<?php

namespace App\Services;

use App\Models\User;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Laravel\Firebase\Facades\Firebase;
use Illuminate\Support\Facades\Log;
use Twilio\Rest\Client;

class NotificationService
{
    /**
     * Send a notification to users within a specific radius.
     */
    public function notifyNearbyUsers(float $lat, float $lng, float $radiusKm, string $title, string $body, array $data = [])
    {
        // 1. PUSH NOTIFICATIONS (FCM)
        $users = User::select('fcm_token', 'phone')
            ->whereNotNull('fcm_token')
            ->whereRaw(
                "(6371 * acos(cos(radians(?)) * cos(radians(last_lat)) * cos(radians(last_lng) - radians(?)) + sin(radians(?)) * sin(radians(last_lat)))) <= ?",
                [$lat, $lng, $lat, $radiusKm]
            )
            ->get();

        $tokens = $users->pluck('fcm_token')->filter()->toArray();

        if (!empty($tokens)) {
            $messaging = Firebase::messaging();
            $notification = Notification::create($title, $body);
            $message = CloudMessage::new()->withNotification($notification)->withData($data);

            try {
                $messaging->sendMulticast($message, $tokens);
            } catch (\Exception $e) {
                Log::error("FCM Error: " . $e->getMessage());
            }
        }

        // 2. SMS GATEWAY (Twilio Foundation)
        // Note: Requires TWILIO_SID, TWILIO_AUTH_TOKEN, and TWILIO_NUMBER in .env
        $this->sendSMSAlerts($users, $body);
    }

    /**
     * Broadcast an official verified alert to nearby users based on alert type.
     */
    public function broadcastAlert(\App\Models\MissingChild $child)
    {
        $type = $child->alert_type ?? 'child_missing';

        switch ($type) {
            case 'wanted_person':
                $title = "⚠️ AVIS DE RECHERCHE : {$child->name}";
                $body = "Un avis de recherche a été émis par les autorités dans votre zone. Consultez l'application pour plus d'informations.";
                break;
            case 'adult_missing':
                $title = "🚨 DISPARITION INQUIÉTANTE : {$child->name}";
                $body = "Une personne a disparu près de votre position. Consultez l'application pour aider aux recherches.";
                break;
            case 'child_missing':
            default:
                $title = "🚨 ALERTE ENLÈVEMENT : {$child->name}";
                $body = "Un enfant a disparu près de chez vous. Ouvrez l'application pour consulter sa description.";
                break;
        }

        $this->notifyNearbyUsers(
            $child->disappearance_lat,
            $child->disappearance_lng,
            10.0,
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

    private function sendSMSAlerts($users, $message)
    {
        $sid = config('services.twilio.sid');
        $token = config('services.twilio.token');
        $from = config('services.twilio.from');

        if (!$sid || !$token || !$from) {
            Log::warning("SMS Gateway not configured. Missing Twilio credentials.");
            return;
        }

        foreach ($users as $user) {
            if ($user->phone) {
                try {
                    $client = new Client($sid, $token);
                    $client->messages->create($user->phone, [
                        'from' => $from, 
                        'body' => $message
                    ]);
                    Log::info("SMS Alert sent to {$user->phone}");
                } catch (\Exception $e) {
                    Log::error("SMS Error: " . $e->getMessage());
                }
            }
        }
    }
}
