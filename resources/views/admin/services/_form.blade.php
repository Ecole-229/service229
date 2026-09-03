<div class="form-grid">
<div class="form-group">
    <label for="name">Nom du service</label>
    <input id="name" name="name" type="text" value="{{ old('name', $service->name ?? '') }}" required>
</div>
<div class="form-group">
    <label for="category_id">Catégorie</label>
    <select id="category_id" name="category_id" required>
        <option value="">Sélectionner</option>
        @foreach($categories as $category)
            <option value="{{ $category->id }}" @selected(old('category_id', $service->category_id ?? '') == $category->id)>{{ $category->name }}</option>
        @endforeach
    </select>
</div>
</div>
<div class="form-actions"><a class="btn btn-outline" href="{{ route('admin.services.index') }}">Annuler</a><button class="btn btn-primary">Enregistrer</button></div>
