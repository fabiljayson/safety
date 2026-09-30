<?php

namespace App\Http\Controllers;

use App\Models\MissingChild;
use App\Models\Report;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReportController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'missing_child_id' => 'required|exists:missing_children,id',
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'description' => 'nullable|string',
            'sighted_at' => 'required|date',
            'photo' => 'nullable|image|max:2048',
        ]);

        // Sightings may only be attached to a published alert, otherwise they
        // would leak the location of a report that is still pending review.
        $this->authorizeTarget($request, MissingChild::findOrFail($validated['missing_child_id']));

        // Persist only validated fields: reporting the raw request would allow
        // injecting user_id, tracking_path or photo_url.
        $data = collect($validated)->except(['photo', 'missing_child_id'])->all();
        $data['missing_child_id'] = $validated['missing_child_id'];
        $data['user_id'] = $request->user()->id;

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('reports', 'public');
            $data['photo_url'] = Storage::url($path);
        }

        $report = Report::create($data);

        return response()->json($report, 201);
    }

    public function index(Request $request)
    {
        $validated = $request->validate([
            'missing_child_id' => 'required|exists:missing_children,id',
        ]);

        $child = MissingChild::findOrFail($validated['missing_child_id']);
        $this->authorizeTarget($request, $child);

        return Report::where('missing_child_id', $child->id)
            ->with(['user' => fn ($q) => $q->select(User::publicColumns())])
            ->latest()
            ->get();
    }

    /**
     * Sightings on a pending alert are restricted to its reporter and to
     * authorities; everyone else would otherwise see the unverified report.
     */
    private function authorizeTarget(Request $request, MissingChild $child): void
    {
        $user = $request->user();

        if ($child->is_verified) {
            return;
        }

        if ($user->can('verifyAlerts') || $user->id === $child->user_id) {
            return;
        }

        abort(403, 'Unauthorized.');
    }
}
