<?php

namespace Tests\Feature;

use App\Models\MissingChild;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery\MockInterface;
use Tests\TestCase;

/**
 * Regression tests for the authorization and mass-assignment holes that let a
 * regular user publish and broadcast an alert without any authority.
 */
class MissingChildAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    private function fakeBroadcast(): void
    {
        $this->mock(NotificationService::class, function (MockInterface $mock): void {
            $mock->shouldReceive('broadcastAlert')->andReturnNull();
        });
    }

    private function validPayload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'Alice Smith',
            'age' => 8,
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay()->toDateTimeString(),
        ], $overrides);
    }

    public function test_a_citizen_cannot_self_register_as_an_authority(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Sneaky',
            'email' => 'sneaky@example.com',
            'password' => 'password123',
            'role' => 'authority',
        ])->assertOk();

        $this->assertSame('citizen', User::where('email', 'sneaky@example.com')->value('role'));
    }

    public function test_a_whitelisted_address_may_register_as_an_authority(): void
    {
        config(['app.authority_emails' => ['chief@example.org']]);

        $this->postJson('/api/register', [
            'name' => 'Chief',
            'email' => 'chief@example.org',
            'password' => 'password123',
            'role' => 'authority',
        ])->assertOk();

        $this->assertSame('authority', User::where('email', 'chief@example.org')->value('role'));
    }

    public function test_a_parent_registration_keeps_the_parent_role(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Jean',
            'email' => 'jean@example.com',
            'password' => 'password123',
            'role' => 'parent',
        ])->assertOk();

        $this->assertSame('parent', User::where('email', 'jean@example.com')->value('role'));
    }

    public function test_a_citizen_cannot_self_verify_their_own_alert_via_update(): void
    {
        $owner = User::factory()->parent()->create();
        $child = MissingChild::create([
            'user_id' => $owner->id,
            'name' => 'Alice',
            'age' => 8,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => false,
        ]);

        $this->actingAs($owner)
            ->putJson("/api/missing-children/{$child->id}", [
                'is_verified' => true,
                'status' => 'missing',
            ])
            ->assertOk();

        $this->assertFalse(
            (bool) $child->fresh()->is_verified,
            'A citizen must not be able to publish their own alert.'
        );
    }

    public function test_an_authority_may_verify_through_update(): void
    {
        $authority = User::factory()->authority()->create();
        $child = MissingChild::create([
            'user_id' => User::factory()->parent()->create()->id,
            'name' => 'Lucas',
            'age' => 5,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => false,
        ]);

        $this->actingAs($authority)
            ->putJson("/api/missing-children/{$child->id}", ['is_verified' => true])
            ->assertOk();

        $this->assertTrue((bool) $child->fresh()->is_verified);
    }

    public function test_marking_an_alert_found_does_not_unverify_it(): void
    {
        $authority = User::factory()->authority()->create();
        $child = MissingChild::create([
            'user_id' => User::factory()->parent()->create()->id,
            'name' => 'Lucas',
            'age' => 5,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => true,
        ]);

        // An omitted is_verified must not be coerced to false, otherwise
        // closing an alert would silently retract it from the public feed.
        $this->actingAs($authority)
            ->putJson("/api/missing-children/{$child->id}", ['status' => 'found'])
            ->assertOk();

        $child->refresh();

        $this->assertSame('found', $child->status);
        $this->assertTrue((bool) $child->is_verified);
    }

    public function test_an_authority_may_unverify_an_alert_explicitly(): void
    {
        $authority = User::factory()->authority()->create();
        $child = MissingChild::create([
            'user_id' => User::factory()->parent()->create()->id,
            'name' => 'Lucas',
            'age' => 5,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => true,
        ]);

        // Retracting a false alarm has to stay possible, so an explicit false
        // is honoured.
        $this->actingAs($authority)
            ->putJson("/api/missing-children/{$child->id}", ['is_verified' => false])
            ->assertOk();

        $this->assertFalse((bool) $child->fresh()->is_verified);
    }

    public function test_update_ignores_unvalidated_fields(): void
    {
        $owner = User::factory()->parent()->create();
        $child = MissingChild::create([
            'user_id' => $owner->id,
            'name' => 'Alice',
            'age' => 8,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => false,
        ]);

        $this->actingAs($owner)
            ->putJson("/api/missing-children/{$child->id}", [
                'user_id' => 999,
                'name' => 'Injected',
                'disappearance_lat' => 0,
                'photo_url' => 'https://evil.example.com/x.png',
            ])
            ->assertOk();

        $fresh = $child->fresh();
        $this->assertSame($owner->id, $fresh->user_id);
        $this->assertSame('Alice', $fresh->name);
        $this->assertEquals(48.8566, (float) $fresh->disappearance_lat);
        $this->assertNull($fresh->photo_url);
    }

    public function test_store_ignores_injected_privileged_fields(): void
    {
        $this->fakeBroadcast();

        $citizen = User::factory()->citizen()->create();
        $victim = User::factory()->parent()->create();

        $response = $this->actingAs($citizen)
            ->postJson('/api/missing-children', $this->validPayload([
                'user_id' => $victim->id,
                'is_verified' => true,
                'status' => 'found',
                'photo_url' => 'https://evil.example.com/x.png',
            ]))
            ->assertCreated();

        $id = $response->json('id');

        // status/photo_url are database defaults, so assert on the stored row.
        $this->assertDatabaseHas('missing_children', [
            'id' => $id,
            'user_id' => $citizen->id,
            'is_verified' => false,
            'status' => 'missing',
            'photo_url' => null,
        ]);
    }

    public function test_a_citizen_cannot_verify_an_alert(): void
    {
        $child = MissingChild::create([
            'user_id' => User::factory()->parent()->create()->id,
            'name' => 'Alice',
            'age' => 8,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => false,
        ]);

        $this->actingAs(User::factory()->citizen()->create())
            ->postJson("/api/missing-children/{$child->id}/verify")
            ->assertForbidden()
            // The API speaks English to the client; a French string here would
            // surface verbatim in the app's error snackbar.
            ->assertJson(['message' => 'Unauthorized. Only authorities can verify an alert.']);

        $this->assertFalse((bool) $child->fresh()->is_verified);
    }

    public function test_verifying_twice_broadcasts_only_once(): void
    {
        $child = MissingChild::create([
            'user_id' => User::factory()->parent()->create()->id,
            'name' => 'Alice',
            'age' => 8,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => false,
        ]);

        $this->mock(NotificationService::class, function (MockInterface $mock): void {
            $mock->shouldReceive('broadcastAlert')->once()->andReturnNull();
        });

        $authority = User::factory()->authority()->create();

        $this->actingAs($authority)->postJson("/api/missing-children/{$child->id}/verify")->assertOk();
        $this->actingAs($authority)->postJson("/api/missing-children/{$child->id}/verify")->assertOk();
    }

    public function test_a_stranger_cannot_read_a_pending_alert(): void
    {
        $child = MissingChild::create([
            'user_id' => User::factory()->parent()->create()->id,
            'name' => 'Alice',
            'age' => 8,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => false,
        ]);

        $this->actingAs(User::factory()->citizen()->create())
            ->getJson("/api/missing-children/{$child->id}")
            ->assertForbidden();
    }

    public function test_the_reporter_can_read_their_own_pending_alert(): void
    {
        $owner = User::factory()->parent()->create();
        $child = MissingChild::create([
            'user_id' => $owner->id,
            'name' => 'Alice',
            'age' => 8,
            'status' => 'missing',
            'disappearance_lat' => 48.8566,
            'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(),
            'is_verified' => false,
        ]);

        $this->actingAs($owner)
            ->getJson("/api/missing-children/{$child->id}")
            ->assertOk();
    }

    public function test_a_pending_alert_is_absent_from_the_public_feed(): void
    {
        $owner = User::factory()->parent()->create();

        MissingChild::create([
            'user_id' => $owner->id, 'name' => 'Pending', 'age' => 8, 'status' => 'missing',
            'disappearance_lat' => 48.8566, 'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(), 'is_verified' => false,
        ]);

        MissingChild::create([
            'user_id' => $owner->id, 'name' => 'Published', 'age' => 5, 'status' => 'missing',
            'disappearance_lat' => 48.8566, 'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(), 'is_verified' => true,
        ]);

        $response = $this->actingAs(User::factory()->citizen()->create())
            ->getJson('/api/missing-children')
            ->assertOk();

        $names = array_column($response->json(), 'name');
        $this->assertSame(['Published'], $names);
    }

    public function test_my_reports_never_returns_another_users_alerts(): void
    {
        $owner = User::factory()->parent()->create();
        $stranger = User::factory()->parent()->create();

        MissingChild::create([
            'user_id' => $stranger->id, 'name' => 'NotMine', 'age' => 8, 'status' => 'missing',
            'disappearance_lat' => 48.8566, 'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(), 'is_verified' => false,
        ]);

        $response = $this->actingAs($owner)
            ->getJson('/api/missing-children?my_reports=1')
            ->assertOk();

        $this->assertSame([], $response->json());
    }

    public function test_nested_user_data_never_exposes_the_push_token(): void
    {
        $owner = User::factory()->parent()->create([
            'fcm_token' => 'super-secret-fcm-token',
            'last_lat' => 48.8566,
            'last_lng' => 2.3522,
        ]);

        $child = MissingChild::create([
            'user_id' => $owner->id, 'name' => 'Alice', 'age' => 8, 'status' => 'missing',
            'disappearance_lat' => 48.8566, 'disappearance_lng' => 2.3522,
            'disappeared_at' => now()->subDay(), 'is_verified' => true,
        ]);

        $json = $this->actingAs(User::factory()->citizen()->create())
            ->getJson("/api/missing-children/{$child->id}")
            ->assertOk()
            ->json('user');

        $this->assertArrayNotHasKey('fcm_token', $json);
        $this->assertArrayNotHasKey('last_lat', $json);
        $this->assertArrayNotHasKey('email', $json);
        $this->assertSame($owner->name, $json['name']);
    }
}
