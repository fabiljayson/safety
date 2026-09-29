<?php

namespace App\Http\Controllers;

use App\Models\MissingChild;
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
        $query = MissingChild::with('user')->latest();

        // If requesting my reports, show all reports belonging to the user (verified and pending)
        if ($request->boolean('my_reports')) {
            $query->where('user_id', $request->user()->id);
        } else {
            // Public feed: only verified alerts unless user is authority
            $isAuthority = $request->user() && $request->user()->role === 'authority';
            if (!$isAuthority) {
                $query->where('is_verified', true);
            }
        }

        // Filter by alert_type if provided
        if ($request->filled('alert_type') && $request->alert_type !== 'all') {
            $query->where('alert_type', $request->alert_type);
        }

        // Filter by status if provided (default: missing)
        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        } else {
            $query->where('status', 'missing');
        }

        return $query->get();
    }

    public function store(Request $request)
    {
        $request->validate([
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

        $data = $request->except('photo');
        $data['user_id'] = $request->user()->id;
        $data['alert_type'] = $request->input('alert_type', 'child_missing');

        $isAuthority = $request->user()->role === 'authority';
        
        // If created by an authority, it is immediately verified and published.
        // If created by a citizen, it requires prior verification by authorities before broadcast.
        $data['is_verified'] = $isAuthority;

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('missing_children', 'public');
            $data['photo_url'] = Storage::url($path);
        }

        $child = MissingChild::create($data);

        // Only trigger instant mass notification if created directly by an authority
        if ($child->is_verified) {
            $this->notificationService->broadcastAlert($child);
        }

        return response()->json($child, 201);
    }

    public function show(MissingChild $missingChild)
    {
        return $missingChild->load(['user', 'reports.user']);
    }

    public function update(Request $request, MissingChild $missingChild)
    {
        // Only the reporting user or an authority can update
        if ($request->user()->id !== $missingChild->user_id && $request->user()->role !== 'authority') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $request->validate([
            'status' => 'sometimes|in:missing,found',
            'alert_type' => 'sometimes|in:child_missing,adult_missing,wanted_person',
            'is_verified' => 'sometimes|boolean',
        ]);

        $wasVerified = $missingChild->is_verified;
        $missingChild->update($request->all());

        // If an authority just verified the alert via update, broadcast notification
        if (!$wasVerified && $missingChild->is_verified) {
            $this->notificationService->broadcastAlert($missingChild);
        }

        return response()->json($missingChild);
    }

    public function verify(Request $request, MissingChild $missingChild)
    {
        if ($request->user()->role !== 'authority') {
            return response()->json(['message' => 'Non autorisé. Seules les autorités peuvent vérifier une alerte.'], 403);
        }

        $missingChild->update(['is_verified' => true]);

        // Broadcast notifications to nearby users (10km) on verification
        $this->notificationService->broadcastAlert($missingChild);

        return response()->json(['message' => 'Alerte vérifiée et diffusée avec succès', 'child' => $missingChild]);
    }
}
