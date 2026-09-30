<?php

namespace App\Http\Controllers;

use App\Models\MissingChild;
use App\Models\Report;
use App\Models\User;
use App\Services\NotificationService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    public function index(Request $request)
    {
        $stats = [
            'total_missing' => MissingChild::where('status', 'missing')->count(),
            'total_found' => MissingChild::where('status', 'found')->count(),
            'pending_verification' => MissingChild::where('is_verified', false)->count(),
            'total_children' => MissingChild::where('alert_type', 'child_missing')->count(),
            'total_adults' => MissingChild::where('alert_type', 'adult_missing')->count(),
            'total_wanted' => MissingChild::where('alert_type', 'wanted_person')->count(),
            'recent_reports' => Report::with([
                'missingChild',
                'user' => fn ($q) => $q->select(User::publicColumns()),
            ])->latest()->take(5)->get(),
        ];

        $query = MissingChild::with([
            'user' => fn ($q) => $q->select(User::publicColumns()),
            'reports',
        ])->latest();

        if ($request->filled('type') && $request->type !== 'all') {
            $query->where('alert_type', $request->type);
        }

        if ($request->filled('filter_status')) {
            if ($request->filter_status === 'pending') {
                $query->where('is_verified', false);
            } elseif ($request->filter_status === 'verified') {
                $query->where('is_verified', true);
            } elseif ($request->filter_status === 'found') {
                $query->where('status', 'found');
            }
        }

        $children = $query->paginate(10)->withQueryString();

        $dangerZones = Report::select(
            DB::raw('ROUND(lat, 3) as lat'),
            DB::raw('ROUND(lng, 3) as lng'),
            DB::raw('COUNT(*) as intensity')
        )
            ->groupBy('lat', 'lng')
            ->get();

        return view('admin.dashboard', compact('stats', 'children', 'dangerZones'));
    }

    public function exportPdf(Request $request)
    {
        $query = MissingChild::where('status', 'missing')->with(['user' => fn ($q) => $q->select(User::publicColumns())]);
        if ($request->filled('type') && $request->type !== 'all') {
            $query->where('alert_type', $request->type);
        }
        $children = $query->get();
        $pdf = Pdf::loadView('admin.reports.missing_pdf', compact('children'));

        return $pdf->download('avis-recherches-'.now()->format('d-m-Y').'.pdf');
    }

    public function verifyChild(MissingChild $child)
    {
        // Only broadcast on the transition, so a double-clicked "validate"
        // button cannot mass-text every nearby phone twice.
        $wasVerified = (bool) $child->is_verified;

        $child->update(['is_verified' => true]);

        if (! $wasVerified) {
            $this->notificationService->broadcastAlert($child);
        }

        return back()->with('success', "Le signalement de {$child->name} a été validé et diffusé aux citoyens alentours.");
    }

    public function markAsFound(MissingChild $child)
    {
        $child->update(['status' => 'found']);

        return back()->with('success', "Le dossier de {$child->name} a été clôturé (Retrouvé(e)).");
    }
}
