<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class PasswordResetController extends Controller
{
    /**
     * Number of wrong codes tolerated before the stored OTP is destroyed.
     * The code space is only 1,000,000, so without this a leaked code would
     * be trivially recoverable.
     */
    private const MAX_TOKEN_ATTEMPTS = 5;

    public function sendResetToken(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        if (! $user) {
            // We return success even if user not found for security reasons
            return response()->json(['message' => 'Si cet email existe, un code de réinitialisation a été envoyé.']);
        }

        // Generate a 6-digit OTP
        $token = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Store token in password_reset_tokens table
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $user->email],
            [
                'token' => Hash::make($token),
                'attempts' => 0,
                'created_at' => now(),
            ]
        );

        // Send Email
        try {
            Mail::send([], [], function ($message) use ($user, $token) {
                $message->to($user->email)
                    ->subject('Code de réinitialisation Safety 🛡️')
                    ->html("<h1>Réinitialisation de mot de passe</h1>
                           <p>Bonjour {$user->name},</p>
                           <p>Votre code de réinitialisation est : <b>{$token}</b></p>
                           <p>Ce code expirera dans 60 minutes.</p>");
            });
        } catch (\Exception $e) {
            Log::error('Password reset email failed: '.$e->getMessage());

            return response()->json(['message' => 'Erreur lors de l\'envoi de l\'email.'], 500);
        }

        return response()->json(['message' => 'Un code de réinitialisation a été envoyé à votre adresse email.']);
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'token' => 'required|string|size:6',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $record = DB::table('password_reset_tokens')->where('email', $request->email)->first();

        if (! $record || ! Hash::check($request->token, $record->token)) {
            if ($record) {
                // Five failed attempts invalidate the code, so a leaked OTP
                // cannot be brute-forced even if the caller rotates IPs to
                // dodge the per-address route rate limiter.
                $attempts = (int) $record->attempts + 1;

                if ($attempts >= self::MAX_TOKEN_ATTEMPTS) {
                    DB::table('password_reset_tokens')->where('email', $request->email)->delete();

                    Log::warning('Password reset token locked after too many attempts.', [
                        'email' => $request->email,
                    ]);

                    throw ValidationException::withMessages([
                        'token' => ['Trop de tentatives incorrectes. Veuillez demander un nouveau code.'],
                    ]);
                }

                DB::table('password_reset_tokens')
                    ->where('email', $request->email)
                    ->update(['attempts' => $attempts]);
            }

            throw ValidationException::withMessages(['token' => ['Le code de réinitialisation est invalide ou a expiré.']]);
        }

        // Check expiry (1 hour)
        if (now()->parse($record->created_at)->addHour()->isPast()) {
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();

            throw ValidationException::withMessages(['token' => ['Ce code a expiré. Veuillez en demander un nouveau.']]);
        }

        $user = User::where('email', $request->email)->first();

        if (! $user) {
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();

            throw ValidationException::withMessages(['email' => ['Ce compte n\'existe plus.']]);
        }

        $user->update(['password' => Hash::make($request->password)]);

        // A reset is the usual response to a suspected compromise, so every
        // existing credential must stop working: revoke all API tokens and
        // invalidate all web sessions.
        $user->tokens()->delete();
        DB::table('sessions')->where('user_id', $user->id)->delete();

        // Delete token
        DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        return response()->json(['message' => 'Votre mot de passe a été réinitialisé avec succès.']);
    }
}
