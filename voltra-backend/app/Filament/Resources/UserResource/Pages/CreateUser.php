<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use App\Models\Wallet;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Support\Facades\Hash;

class CreateUser extends CreateRecord
{
    protected static string $resource = UserResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        // Set a default password and PIN for admin-created users
        $data['password'] = Hash::make('password');
        $data['pin']      = Hash::make('123456');

        return $data;
    }

    protected function afterCreate(): void
    {
        // Auto-create wallet for new user
        Wallet::create([
            'user_id' => $this->record->id,
            'balance' => '0.00',
        ]);
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
