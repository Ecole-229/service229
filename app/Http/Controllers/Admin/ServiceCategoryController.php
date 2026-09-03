<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ServiceCategory;
use App\Services\Admin\ActivityLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ServiceCategoryController extends Controller
{
    public function index(): View
    {
        return view('admin.categories.index', [
            'categories' => ServiceCategory::query()
                ->withCount('services')
                ->orderBy('name')
                ->paginate(12),
        ]);
    }

    public function create(): View
    {
        return view('admin.categories.create');
    }

    public function store(Request $request, ActivityLogger $logger): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100', 'unique:service_categories,name'],
        ]);

        ServiceCategory::create($data);
        $logger->log($request->user()?->id, 'Création de la catégorie : ' . $data['name']);

        return redirect()->route('admin.categories.index')
            ->with('success', 'Catégorie créée.');
    }

    public function edit(ServiceCategory $category): View
    {
        return view('admin.categories.edit', compact('category'));
    }

    public function update(Request $request, ServiceCategory $category, ActivityLogger $logger): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100', 'unique:service_categories,name,' . $category->id],
        ]);

        $category->update($data);
        $logger->log($request->user()?->id, 'Modification de la catégorie : ' . $category->name);

        return redirect()->route('admin.categories.index')
            ->with('success', 'Catégorie mise à jour.');
    }
}
