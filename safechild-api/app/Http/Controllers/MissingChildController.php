<?php

namespace App\Http\Controllers;

use App\Models\MissingChild;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MissingChildController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    public function index(Request $request)
    {
        $query = MissingChild::with(['user' => fn ($q) => $q->select(User::publicColumns())])->latest();

        $user = $request->user();
        $isAuthority = $user && $user->role === 'authority';

        if ($request->boolean('my_reports')) {
            // A user may only ever list their own reports. This is restricted
            // to the authenticated user rather than trusting an id parameter.
            $query->where('user_id', $user->id);
        } elseif (! $isAuthority) {
            // Public feed: only verified alerts are visible to non-authorities.
            $query->where('is_verified', true);
        }

        if ($request->filled('alert_type') && $request->alert_type !== 'all') {
            $query->where('alert_type', $request->alert_type);
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        } else {
            $query->where('status', 'missing');
        }

        return $query->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'age' => 'required|integer',
            'alert_type' => 'nullable|in:child_missing,adult_missing,wanted_person',
            'description' => 'nullable|string',
            'last_clothes' => 'nullable|string',
            'disappearance_lat' => 'required|numeric',
            'disappearance_lng' => 'required|numeric',
            'disappeared_at' => 'required|date',
            'photo' => 'nullable|image|max:2048',
        ]);

        // Only explicitly validated fields are persisted. Using the raw
        // request here would let a caller inject user_id, is_verified,
        // status or photo_url, which are all mass assignable.
        $data = collect($validated)->except('photo')->all();
        $data['user_id'] = $request->user()->id;
        $data['alert_type'] = $validated['alert_type'] ?? 'child_missing';

        // Authorities publish immediately; citizen reports stay pending until
        // an authority verifies them.
        $data['is_verified'] = $this->isAuthority($request);

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('missing_children', 'public');
            $data['photo_url'] = Storage::url($path);
        }

        $child = MissingChild::create($data);

        if ($child->is_verified) {
            $this->notificationService->broadcastAlert($child);
        }

        return response()->json($child, 201);
    }

    public function show(Request $request, MissingChild $missingChild)
    {
        $this->authorizeVisibility($request, $missingChild);

        return $missingChild->load([
            'user' => fn ($q) => $q->select(User::publicColumns()),
            'reports.user' => fn ($q) => $q->select(User::publicColumns()),
        ]);
    }

    public function update(Request $request, MissingChild $missingChild)
    {
        $isAuthority = $this->isAuthority($request);

        if (! $isAuthority && $request->user()->id !== $missingChild->user_id) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $validated = $request->validate([
            'status' => 'sometimes|in:missing,found',
            'alert_type' => 'sometimes|in:child_missing,adult_missing,wanted_person',
        ]);

        // is_verified is deliberately not accepted from this endpoint: it is
        // the authority-only gate for broadcasting an alert, and accepting it
        // here let a citizen self-verify their own report. Authorities use
        // the dedicated /verify endpoint.
        //
        // Only write the flag when the caller actually sent it. Reading it
        // unconditionally would default the omitted field to false, so an
        // authority marking an alert "found" would silently un-verify it and
        // drop it out of the public feed without a broadcast.
        if ($isAuthority && $request->has('is_verified')) {
            $validated['is_verified'] = $request->boolean('is_verified');
        }

        $wasVerified = (bool) $missingChild->is_verified;

        $missingChild->update($validated);

        if (! $wasVerified && $missingChild->is_verified) {
            $this->notificationService->broadcastAlert($missingChild);
        }

        return response()->json($missingChild);
    }

    public function verify(Request $request, MissingChild $missingChild)
    {
        if (! $this->isAuthority($request)) {
            return response()->json(['message' => 'Non autorisé. Seules les autorités peuvent vérifier une alerte.'], 403);
        }

        // Only broadcast on the transition, so re-verifying an alert does not
        // spam every nearby phone a second time.
        $wasVerified = (bool) $missingChild->is_verified;

        $missingChild->update(['is_verified' => true]);

        if (! $wasVerified) {
            $this->notificationService->broadcastAlert($missingChild);
        }

        return response()->json(['message' => 'Alerte vérifiée et diffusée avec succès', 'child' => $missingChild]);
    }

    private function isAuthority(Request $request): bool
    {
        return (bool) $request->user()?->can('verifyAlerts');
    }

    /**
     * Pending reports are only readable by the reporter and by authorities.
     */
    private function authorizeVisibility(Request $request, MissingChild $missingChild): void
    {
        $user = $request->user();

        if ($missingChild->is_verified) {
            return;
        }

        if ($this->isAuthority($request) || $user->id === $missingChild->user_id) {
            return;
        }

        abort(403, 'Non autorisé.');
    }
}
