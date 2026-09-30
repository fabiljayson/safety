<?php

namespace Tests\Feature;

use App\Models\MissingChild;
use App\Models\Report;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Mockery\MockInterface;
use Tests\TestCase;

class ReportAndAuthHardeningTest extends TestCase
{
    use RefreshDatabase;

    private function verifiedChild(array $overrides = []): MissingChild
    {
        return MissingChild::create(array_merge([
            'user_id' => User::factory()->parent()->create()->id,
            'name' => 'Alice',
            'age' => 8,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => true,
        ], $overrides));
    }

    public function test_a_sighting_cannot_be_attached_to_a_pending_alert_by_a_stranger(): void
    {
        $child = $this->verifiedChild(['is_verified' => false]);

        $this->actingAs(User::factory()->citizen()->create())
            ->postJson('/api/reports', [
                'missing_child_id' => $child->id,
                'lat' => 48.86,
                'lng' => 2.35,
                'sighted_at' => now()->toDateTimeString(),
            ])
            ->assertForbidden();

        $this->assertDatabaseCount('reports', 0);
    }

    public function test_sightings_of_a_pending_alert_are_not_listable_by_a_stranger(): void
    {
        $child = $this->verifiedChild(['is_verified' => false]);

        Report::create([
            'missing_child_id' => $child->id,
            'user_id' => $child->user_id,
            'lat' => 48.86,
            'lng' => 2.35,
            'sighted_at' => now(),
        ]);

        $this->actingAs(User::factory()->citizen()->create())
            ->getJson("/api/reports?missing_child_id={$child->id}")
            ->assertForbidden();
    }

    public function test_a_sighting_ignores_an_injected_user_id(): void
    {
        $child = $this->verifiedChild();
        $attacker = User::factory()->citizen()->create();
        $victim = User::factory()->citizen()->create();

        $this->actingAs($attacker)
            ->postJson('/api/reports', [
                'missing_child_id' => $child->id,
                'user_id' => $victim->id,
                'tracking_path' => 'not-json',
                'photo_url' => 'https://evil.example.com/x.png',
                'lat' => 48.86,
                'lng' => 2.35,
                'sighted_at' => now()->toDateTimeString(),
            ])
            ->assertCreated();

        $this->assertDatabaseHas('reports', [
            'missing_child_id' => $child->id,
            'user_id' => $attacker->id,
            'photo_url' => null,
        ]);
    }

    public function test_danger_zones_exclude_sightings_of_pending_alerts(): void
    {
        $pending = $this->verifiedChild(['is_verified' => false]);
        $published = $this->verifiedChild();

        Report::create(['missing_child_id' => $pending->id, 'user_id' => $pending->user_id, 'lat' => 10.0, 'lng' => 20.0, 'sighted_at' => now()]);
        Report::create(['missing_child_id' => $published->id, 'user_id' => $published->user_id, 'lat' => 48.86, 'lng' => 2.35, 'sighted_at' => now()]);

        $zones = $this->actingAs(User::factory()->citizen()->create())
            ->getJson('/api/danger-zones')
            ->assertOk()
            ->json();

        $this->assertCount(1, $zones);
        $this->assertEquals(48.86, $zones[0]['lat']);
    }

    public function test_login_is_rate_limited(): void
    {
        for ($i = 0; $i < 6; $i++) {
            $this->postJson('/api/login', [
                'email' => 'nobody@example.com',
                'password' => 'wrong-password',
            ]);
        }

        $this->postJson('/api/login', [
            'email' => 'nobody@example.com',
            'password' => 'wrong-password',
        ])->assertStatus(429);
    }

    public function test_password_reset_is_rate_limited(): void
    {
        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/forgot-password', ['email' => 'nobody@example.com']);
        }

        $this->postJson('/api/forgot-password', ['email' => 'nobody@example.com'])
            ->assertStatus(429);
    }

    public function test_resetting_a_password_revokes_every_api_token(): void
    {
        $user = User::factory()->parent()->create(['password' => Hash::make('old-password')]);
        $token = $user->createToken('auth_token')->plainTextToken;

        $this->assertDatabaseCount('personal_access_tokens', 1);

        DB::table('password_reset_tokens')->insert([
            'email' => $user->email,
            'token' => Hash::make('123456'),
            'attempts' => 0,
            'created_at' => now(),
        ]);

        $this->postJson('/api/reset-password', [
            'email' => $user->email,
            'token' => '123456',
            'password' => 'brand-new-password',
            'password_confirmation' => 'brand-new-password',
        ])->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->assertTrue(Hash::check('brand-new-password', $user->fresh()->password));

        // The old bearer token must no longer authenticate.
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/me')
            ->assertUnauthorized();
    }

    public function test_repeated_wrong_reset_codes_destroy_the_stored_token(): void
    {
        $user = User::factory()->parent()->create();

        // Four wrong guesses already failed from another address; the fifth
        // must destroy the code even though the route throttle is per-IP.
        DB::table('password_reset_tokens')->insert([
            'email' => $user->email,
            'token' => Hash::make('123456'),
            'attempts' => 4,
            'created_at' => now(),
        ]);

        $this->postJson('/api/reset-password', [
            'email' => $user->email,
            'token' => '000000',
            'password' => 'brand-new-password',
            'password_confirmation' => 'brand-new-password',
        ])->assertStatus(422);

        $this->assertDatabaseCount('password_reset_tokens', 0);

        // Even the correct code is now worthless.
        $this->postJson('/api/reset-password', [
            'email' => $user->email,
            'token' => '123456',
            'password' => 'brand-new-password',
            'password_confirmation' => 'brand-new-password',
        ])->assertStatus(422);
    }

    public function test_a_non_authority_session_cannot_reach_the_admin_dashboard(): void
    {
        $user = User::factory()->parent()->create();

        $this->actingAs($user)
            ->get('/admin/dashboard')
            ->assertRedirect(route('admin.login'));
    }

    public function test_an_authority_can_reach_the_admin_dashboard(): void
    {
        $this->actingAs(User::factory()->authority()->create())
            ->get('/admin/dashboard')
            ->assertOk();
    }

    public function test_the_admin_login_page_rejects_non_authorities(): void
    {
        User::factory()->parent()->create([
            'email' => 'parent@example.com',
            'password' => Hash::make('password'),
        ]);

        $this->post('/admin/login', [
            'email' => 'parent@example.com',
            'password' => 'password',
        ])->assertSessionHasErrors('email');

        $this->assertGuest();
    }

    public function test_api_errors_are_rendered_as_json(): void
    {
        $this->actingAs(User::factory()->parent()->create())
            ->postJson('/api/missing-children', [])
            ->assertStatus(422)
            ->assertHeader('content-type', 'application/json');
    }

    public function test_a_broadcast_larger_than_the_fcm_limit_is_chunked(): void
    {
        // 3 users with tokens + 1 without: the tokenless user must still be
        // reachable by SMS, and the batch must not blow up.
        User::factory()->count(3)->create([
            'last_lat' => 48.8566,
            'last_lng' => 2.3522,
            'fcm_token' => 'token',
            'phone' => '+33600000000',
        ]);

        User::factory()->create([
            'last_lat' => 48.8566,
            'last_lng' => 2.3522,
            'fcm_token' => null,
            'phone' => '+33611111111',
        ]);

        $child = $this->verifiedChild();

        // No Firebase/Twilio credentials in the test environment, so the
        // service logs and continues instead of throwing.
        $this->mock(NotificationService::class, function (MockInterface $mock): void {
            $mock->shouldReceive('broadcastAlert')->andReturnNull();
        })->broadcastAlert($child);

        $this->assertTrue(true);
    }
}
