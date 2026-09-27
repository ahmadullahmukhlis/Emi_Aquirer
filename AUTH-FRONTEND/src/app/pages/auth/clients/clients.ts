import { Component, inject } from '@angular/core';
import { DynamicFormBuilder } from '../../../components/ui/dynamic-form-builder/dynamic-form-builder';
import { Datatable } from '../../../components/ui/datatable/datatable';
import { Modal } from '../../../components/ui/modal/modal';
import { DynamicField } from '../../../models/fomrBuilderModel';
import { DataTableConfig } from '../../../models/datatable.model';
import { ApiService } from '../../../services/api/api.service';
import { ComponentService } from '../../../services/genral/component.service';

@Component({
  selector: 'app-auth-clients',
  standalone: true,
  imports: [ DynamicFormBuilder, Datatable, Modal],
  templateUrl: './clients.html',
  styleUrl: './clients.css',
})
export class AuthClients {
  private api = inject(ApiService);
  private componentService = inject(ComponentService);

  showClientModal = false;
  isEdit = false;
  selectedClientId: string | null = null;

  clientFields: DynamicField[] = [
    { type: 'text', name: 'name', label: 'Client Name', required: true },
    { type: 'textarea', name: 'publicKey', label: 'Public Key (PEM)', required: true },
    {
      type: 'textarea',
      name: 'redirectUris',
      label: 'Redirect URIs (comma or newline separated)',
      required: true,
    },
    {
      type: 'checkbox-group',
      name: 'allowedGrantTypes',
      label: 'Allowed Grant Types',
      options: [
        { id: 'authorization_code', name: 'authorization_code' },
        { id: 'refresh_token', name: 'refresh_token' },
        { id: 'client_credentials', name: 'client_credentials' },
      ],
      optionValue: 'id',
      optionLabel: 'name',
    },
    {
      type: 'checkbox-group',
      name: 'allowedScopes',
      label: 'Allowed Scopes',
      options: [
        { id: 'openid', name: 'openid' },
        { id: 'profile', name: 'profile' },
        { id: 'email', name: 'email' },
        { id: 'offline_access', name: 'offline_access' },
      ],
      optionValue: 'id',
      optionLabel: 'name',
    },
    { type: 'switch', name: 'requirePkce', label: 'Require PKCE', defaultValue: true },
  ];

  clientTableConfig: DataTableConfig = {
    onAdd: () => this.openCreate(),
    columns: [
      { key: 'id', label: 'Client ID' },
      { key: 'name', label: 'Name' },
      { key: 'publicKey', label: 'Public Key', type: 'text' },
      { key: 'redirectUris', label: 'Redirect URIs' },
      { key: 'allowedGrantTypes', label: 'Grant Types' },
      { key: 'allowedScopes', label: 'Scopes' },
      { key: 'requirePkce', label: 'PKCE', type: 'boolean' },
    ],
    rowActions: [
      {
        label: 'Edit',
        icon: 'fa-edit',
        action: (row) => this.openEdit(row),
        color: 'primary',
      },
    ],
  };

  openCreate() {
    this.isEdit = false;
    this.selectedClientId = null;
    this.resetDefaults();
    this.showClientModal = true;
  }

  openEdit(row: any) {
    this.isEdit = true;
    this.selectedClientId = row?.id ?? null;
    this.clientFields = this.clientFields.map((f) => ({
      ...f,
      defaultValue: row?.[f.name] ?? null,
    }));
    this.showClientModal = true;
  }

  closeModal() {
    this.showClientModal = false;
  }

  submitClient = (payload: any) => {
    const finalPayload = {
      name: payload.name,
      publicKey: payload.publicKey,
      redirectUris: this.splitList(payload.redirectUris),
      allowedGrantTypes: Array.isArray(payload.allowedGrantTypes)
        ? payload.allowedGrantTypes
        : this.splitList(payload.allowedGrantTypes),
      allowedScopes: Array.isArray(payload.allowedScopes)
        ? payload.allowedScopes
        : this.splitList(payload.allowedScopes),
      requirePkce: payload.requirePkce ?? true,
    };

    if (this.isEdit && this.selectedClientId) {
      this.api.put(`/client/by-id?id=${this.selectedClientId}`, finalPayload).subscribe({
        next: () => {
          this.showClientModal = false;
          this.componentService.revalidate('clients-table');
        },
      });
      return;
    }

    this.api.post('/client', finalPayload).subscribe({
      next: () => {
        this.showClientModal = false;
        this.componentService.revalidate('clients-table');
      },
    });
  };

  private splitList(value: any): string[] {
    if (!value) return [];
    if (Array.isArray(value)) return value;
    return value
      .split(/[\n,]/)
      .map((v: string) => v.trim())
      .filter((v: string) => v.length > 0);
  }

  private resetDefaults() {
    this.clientFields = this.clientFields.map((f) => ({ ...f, defaultValue: null }));
  }
}
