<?php

namespace App\Services;

use App\Models\MissingChild;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Laravel\Firebase\Facades\Firebase;
use Twilio\Rest\Client;

class NotificationService
{
    /**
     * FCM rejects a single multicast request with more than 500 registration
     * tokens, so nearby-user batches have to be split.
     */
    private const FCM_MULTICAST_LIMIT = 500;

    /**
     * Broadcast radius, in kilometres, used for an official alert.
     */
    private const BROADCAST_RADIUS_KM = 10.0;

    /**
     * Send a notification to users within a specific radius.
     */
    public function notifyNearbyUsers(float $lat, float $lng, float $radiusKm, string $title, string $body, array $data = [])
    {
        $users = $this->usersNearby($lat, $lng, $radiusKm);

        $this->sendPushNotifications($users->pluck('fcm_token')->filter()->values()->all(), $title, $body, $data);
        $this->sendSMSAlerts($users, $body);
    }

    /**
     * Users whose last reported position is within the given radius.
     *
     * @return Collection<int, User>
     */
    private function usersNearby(float $lat, float $lng, float $radiusKm)
    {
        return User::select('id', 'fcm_token', 'phone')
            ->whereNotNull('last_lat')
            ->whereNotNull('last_lng')
            // Great-circle distance in km (haversine, earth radius 6371 km).
            ->whereRaw(
                '(6371 * acos(cos(radians(?)) * cos(radians(last_lat)) * cos(radians(last_lng) - radians(?)) + sin(radians(?)) * sin(radians(last_lat)))) <= ?',
                [$lat, $lng, $lat, $radiusKm]
            )
            ->get();
    }

    /**
     * @param  list<string>  $tokens
     */
    private function sendPushNotifications(array $tokens, string $title, string $body, array $data): void
    {
        if ($tokens === []) {
            return;
        }

        $notification = Notification::create($title, $body);
        $message = CloudMessage::new()->withNotification($notification)->withData($data);

        // Chunked: a dense area can produce far more than 500 nearby users and
        // sendMulticast throws for an oversized batch, which previously turned
        // a successful alert into a 500 error.
        foreach (array_chunk($tokens, self::FCM_MULTICAST_LIMIT) as $chunk) {
            try {
                Firebase::messaging()->sendMulticast($message, $chunk);
            } catch (\Throwable $e) {
                Log::error('FCM Error: '.$e->getMessage(), ['batch_size' => count($chunk)]);
            }
        }
    }

    /**
     * Broadcast an official verified alert to nearby users based on alert type.
     */
    public function broadcastAlert(MissingChild $child)
    {
        $type = $child->alert_type ?? 'child_missing';

        switch ($type) {
            case 'wanted_person':
                $title = "⚠️ WANTED NOTICE: {$child->name}";
                $body = 'Authorities have issued a wanted notice in your area. Open the app for more information.';
                break;
            case 'adult_missing':
                $title = "🚨 CONCERNING MISSING PERSON: {$child->name}";
                $body = 'A person has gone missing near your location. Open the app to help with the search.';
                break;
            case 'child_missing':
            default:
                $title = "🚨 KIDNAPPING ALERT: {$child->name}";
                $body = 'A child has gone missing near you. Open the app to read their description.';
                break;
        }

        $this->notifyNearbyUsers(
            (float) $child->disappearance_lat,
            (float) $child->disappearance_lng,
            self::BROADCAST_RADIUS_KM,
            $title,
            $body,
            [
                'child_id' => (string) $child->id,
                'type' => $type,
                'lat' => (string) $child->disappearance_lat,
                'lng' => (string) $child->disappearance_lng,
            ]
        );
    }

    /**
     * @param  Collection<int, User>  $users
     */
    private function sendSMSAlerts($users, string $message): void
    {
        $sid = config('services.twilio.sid');
        $token = config('services.twilio.token');
        $from = config('services.twilio.from');

        if (! $sid || ! $token || ! $from) {
            Log::warning('SMS Gateway not configured. Missing Twilio credentials.');

            return;
        }

        $recipients = $users->filter(fn (User $user): bool => (bool) $user->phone)
            ->pluck('phone')
            ->unique()
            ->values();

        if ($recipients->isEmpty()) {
            return;
        }

        // A single client for the whole batch: constructing one per recipient
        // re-ran the full authentication handshake for every phone.
        $client = new Client($sid, $token);

        foreach ($recipients as $phone) {
            try {
                $client->messages->create($phone, [
                    'from' => $from,
                    'body' => $message,
                ]);
                Log::info("SMS Alert sent to {$phone}");
            } catch (\Throwable $e) {
                Log::error('SMS Error: '.$e->getMessage());
            }
        }
    }
}
