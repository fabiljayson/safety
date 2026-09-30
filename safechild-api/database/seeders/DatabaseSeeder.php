<?php

namespace Database\Seeders;

use App\Models\MissingChild;
use App\Models\Report;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Create Authority
        $authority = User::create([
            'name' => 'National Police',
            'email' => 'police@safechild.gov',
            'password' => Hash::make('password'),
            'role' => 'authority',
            'phone' => '+33100000001',
        ]);

        // 2. Create Citizen/Parent
        $citizen = User::create([
            'name' => 'Jean Parent',
            'email' => 'parent@example.com',
            'password' => Hash::make('password'),
            'role' => 'parent',
            'phone' => '+33612345678',
            'last_lat' => 48.8566,
            'last_lng' => 2.3522,
        ]);

        // 3. Create Missing Children
        $child1 = MissingChild::create([
            'user_id' => $citizen->id,
            'name' => 'Alice Smith',
            'age' => 8,
            'photo_url' => 'https://images.unsplash.com/photo-1517677129300-27b2ae498677?w=300',
            'description' => 'Blonde hair, blue eyes. She has a small beauty mark on her right cheek.',
            'last_clothes' => 'Sparkly red T-shirt, light blue jeans, white sneakers.',
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDays(2),
            'is_verified' => false,
        ]);

        $child2 = MissingChild::create([
            'user_id' => $citizen->id,
            'name' => 'Lucas Martin',
            'age' => 5,
            'photo_url' => 'https://images.unsplash.com/photo-1503919545889-aef636e10ad4?w=300',
            'description' => 'Short brown hair. Round red-framed glasses. Very shy.',
            'last_clothes' => 'Khaki hooded sweatshirt, black tracksuit trousers, green frog backpack.',
            'status' => 'missing',
            'disappearance_lat' => 48.8666,
            'disappearance_lng' => 2.3333,
            'disappeared_at' => now()->subDays(1),
            'is_verified' => true,
        ]);

        // 4. Create Sighting Reports
        Report::create([
            'missing_child_id' => $child1->id,
            'user_id' => $citizen->id,
            'lat' => 48.8584,
            'lng' => 2.3488,
            'description' => 'Seen near the park carousel. She seemed to be looking for her way.',
            'sighted_at' => now()->subDays(1),
        ]);

        Report::create([
            'missing_child_id' => $child1->id,
            'user_id' => $citizen->id,
            'lat' => 48.8530,
            'lng' => 2.3610,
            'description' => 'Appears to be walking with someone wearing a black jacket. She looked tired.',
            'sighted_at' => now()->subHours(12),
        ]);

        Report::create([
            'missing_child_id' => $child2->id,
            'user_id' => $citizen->id,
            'lat' => 48.8700,
            'lng' => 2.3200,
            'description' => 'Spotted sitting alone on a bench near the St-Lazare metro station.',
            'sighted_at' => now()->subHours(6),
        ]);
    }
}
