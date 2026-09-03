<div class="form-group">
    <label for="name">Nom de la catégorie</label>
    <input id="name" name="name" type="text" value="{{ old('name', $category->name ?? '') }}" required>
</div>
<div class="form-actions">
    <a class="btn btn-outline" href="{{ route('admin.categories.index') }}">Annuler</a>
    <button class="btn btn-primary" type="submit">Enregistrer</button>
</div>
