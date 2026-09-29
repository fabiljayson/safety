<?php

namespace App\Http\Controllers;

use App\Models\Report;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReportController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'missing_child_id' => 'required|exists:missing_children,id',
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'description' => 'nullable|string',
            'sighted_at' => 'required|date',
            'photo' => 'nullable|image|max:2048',
        ]);

        $data = $request->except('photo');
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
        $request->validate([
            'missing_child_id' => 'required|exists:missing_children,id',
        ]);

        return Report::where('missing_child_id', $request->missing_child_id)
            ->with('user')
            ->latest()
            ->get();
    }
}
