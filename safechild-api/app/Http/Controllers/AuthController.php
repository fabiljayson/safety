<?php

namespace App\Http\Controllers;

use App\Mail\WelcomeEmail;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'phone' => 'nullable|string',
            'role' => 'nullable|in:parent,citizen,authority',
        ]);

        // "authority" is a privileged role: it can verify alerts, which mass
        // broadcasts push/SMS to every nearby phone. It must never be granted
        // through public self-registration, so the requested role is only
        // honoured for addresses on the config whitelist. Everyone else is
        // downgraded to a regular citizen.
        $requestedRole = $request->input('role', 'citizen');
        $isWhitelisted = in_array(
            strtolower($request->email),
            array_map('strtolower', (array) config('app.authority_emails', [])),
            true
        );

        if ($requestedRole === 'authority' && ! $isWhitelisted) {
            Log::warning('Rejected authority self-registration attempt.', [
                'email' => $request->email,
                'ip' => $request->ip(),
            ]);
        }

        $role = ($requestedRole === 'authority' && $isWhitelisted)
            ? 'authority'
            : ($requestedRole === 'parent' ? 'parent' : 'citizen');

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'role' => $role,
        ]);

        // Send Welcome Email
        try {
            Mail::to($user->email)->send(new WelcomeEmail($user));
        } catch (\Exception $e) {
            Log::error('Failed to send welcome email: '.$e->getMessage());
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Les identifiants fournis sont incorrects.'],
            ]);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Déconnecté avec succès']);
    }

    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    public function updateLocation(Request $request)
    {
        $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
        ]);

        $user = $request->user();
        $user->update([
            'last_lat' => $request->lat,
            'last_lng' => $request->lng,
        ]);

        return response()->json(['message' => 'Localisation mise à jour']);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $request->user()->update([
            'fcm_token' => $request->fcm_token,
        ]);

        return response()->json(['message' => 'FCM token mis à jour']);
    }
}
