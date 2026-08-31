<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreProposalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // vérifié au niveau du controller (isOpenToProposals)
    }

    public function rules(): array
    {
        return [
            'montant' => ['required', 'numeric', 'min:0'],
            'delai' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
        ];
    }
}
