<?php

namespace App\Http\Controllers;

use App\Models\Report;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    public function dangerZones()
    {
        // Clustering logic: group reports by proximity and return weighted intensity
        // We use a finer grid (0.01 degrees) for better visualization
        
        $zones = Report::select(
            DB::raw('ROUND(lat, 4) as lat'),
            DB::raw('ROUND(lng, 4) as lng'),
            DB::raw('COUNT(*) as intensity')
        )
        ->groupBy('lat', 'lng')
        ->get();

        return response()->json($zones);
    }
}
