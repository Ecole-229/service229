<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\View\View;

class UserSupervisionController extends Controller
{
    public function index(Request $request): View
    {
        $query = User::query()->with(['roles', 'providerProfile']);

        if ($request->filled('q')) {
            $term = trim((string) $request->q);
            $query->where(function ($q) use ($term) {
                if (Schema::hasColumn('users', 'name')) {
                    $q->orWhere('name', 'like', "%{$term}%");
                }
                if (Schema::hasColumn('users', 'first_name')) {
                    $q->orWhere('first_name', 'like', "%{$term}%");
                }
                if (Schema::hasColumn('users', 'last_name')) {
                    $q->orWhere('last_name', 'like', "%{$term}%");
                }
                if (Schema::hasColumn('users', 'email')) {
                    $q->orWhere('email', 'like', "%{$term}%");
                }
            });
        }

        return view('admin.users.index', [
            'users' => $query->latest()->paginate(20)->withQueryString(),
        ]);
    }

    public function show(User $user): View
    {
        $user->load(['roles', 'providerProfile']);

        return view('admin.users.show', compact('user'));
    }
}
