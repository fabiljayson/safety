<?php

namespace App\Http\Controllers;

use App\Models\MissingChild;
use App\Models\Report;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    public function dangerZones()
    {
        // Cluster sightings by proximity to produce heatmap intensity.
        // Sightings attached to alerts that are still pending verification are
        // excluded: otherwise this endpoint leaks the exact location of an
        // unverified report to any authenticated user.
        $visibleChildIds = MissingChild::where('is_verified', true)
            ->orWhere('user_id', request()->user()?->id)
            ->pluck('id');

        return Report::whereIn('missing_child_id', $visibleChildIds)
            ->select(
                DB::raw('ROUND(lat, 4) as lat'),
                DB::raw('ROUND(lng, 4) as lng'),
                DB::raw('COUNT(*) as intensity')
            )
            ->groupBy('lat', 'lng')
            ->get();
    }
}
