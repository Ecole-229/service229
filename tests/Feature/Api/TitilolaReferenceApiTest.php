<?php

namespace Tests\Feature\Api;

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\Zone;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TitilolaReferenceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_categories_endpoint_returns_categories(): void
    {
        ServiceCategory::query()->create(["name" => "Carrelage"]);

        $this->getJson("/api/v1/categories")
            ->assertOk()
            ->assertJsonPath("success", true)
            ->assertJsonFragment(["name" => "Carrelage"]);
    }

    public function test_services_can_be_filtered_by_category(): void
    {
        $category = ServiceCategory::query()->create(["name" => "Bâtiment"]);

        Service::query()->create([
            "category_id" => $category->id,
            "name" => "Carrelage",
        ]);

        $this->getJson("/api/v1/services?category_id=".$category->id)
            ->assertOk()
            ->assertJsonPath("success", true)
            ->assertJsonFragment(["name" => "Carrelage"]);
    }

    public function test_zones_endpoint_returns_zones(): void
    {
        Zone::query()->create(["name" => "Tankpè"]);

        $this->getJson("/api/v1/zones")
            ->assertOk()
            ->assertJsonPath("success", true)
            ->assertJsonFragment(["name" => "Tankpè"]);
    }

    public function test_provider_profile_requires_authentication(): void
    {
        $this->getJson("/api/v1/provider-profile")
            ->assertUnauthorized();
    }

    public function test_admin_dashboard_requires_authentication(): void
    {
        $this->getJson("/api/v1/admin/dashboard")
            ->assertUnauthorized();
    }
}
