<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Services\Admin\ActivityLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ServiceController extends Controller
{
    public function index(Request $request): View
    {
        $query = Service::query()->with('category')->orderBy('name');

        if ($request->filled('category')) {
            $query->where('category_id', $request->integer('category'));
        }

        return view('admin.services.index', [
            'services' => $query->paginate(15)->withQueryString(),
            'categories' => ServiceCategory::query()->orderBy('name')->get(),
        ]);
    }

    public function create(): View
    {
        return view('admin.services.create', [
            'categories' => ServiceCategory::query()->orderBy('name')->get(),
        ]);
    }

    public function store(Request $request, ActivityLogger $logger): RedirectResponse
    {
        $data = $request->validate([
            'category_id' => ['required', 'exists:service_categories,id'],
            'name' => ['required', 'string', 'max:120'],
        ]);

        Service::create($data);
        $logger->log($request->user()?->id, 'Création du service : ' . $data['name']);

        return redirect()->route('admin.services.index')
            ->with('success', 'Service créé.');
    }

    public function edit(Service $service): View
    {
        return view('admin.services.edit', [
            'service' => $service,
            'categories' => ServiceCategory::query()->orderBy('name')->get(),
        ]);
    }

    public function update(Request $request, Service $service, ActivityLogger $logger): RedirectResponse
    {
        $data = $request->validate([
            'category_id' => ['required', 'exists:service_categories,id'],
            'name' => ['required', 'string', 'max:120'],
        ]);

        $service->update($data);
        $logger->log($request->user()?->id, 'Modification du service : ' . $service->name);

        return redirect()->route('admin.services.index')
            ->with('success', 'Service mis à jour.');
    }
}
