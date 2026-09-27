import { Component, inject } from '@angular/core';
import { DynamicFormBuilder } from '../../../components/ui/dynamic-form-builder/dynamic-form-builder';
import { Datatable } from '../../../components/ui/datatable/datatable';
import { Modal } from '../../../components/ui/modal/modal';
import { DynamicField } from '../../../models/fomrBuilderModel';
import { DataTableConfig } from '../../../models/datatable.model';
import { ComponentService } from '../../../services/genral/component.service';

@Component({
  selector: 'app-auth-users',
  standalone: true,
  imports: [DynamicFormBuilder, Datatable, Modal],
  templateUrl: './users.html',
  styleUrl: './users.css',
})
export class AuthUsers {
  private componentService = inject(ComponentService);

  showUserModal = false;
  isEdit = false;
  selectedUserId: string | null = null;

  userFields: DynamicField[] = [
    { type: 'text', name: 'username', label: 'Username', required: true },
    { type: 'text', name: 'firstName', label: 'First Name', required: true },
    { type: 'text', name: 'lastName', label: 'Last Name', required: true },
    { type: 'text', name: 'email', label: 'Email', required: true },
    { type: 'password', name: 'password', label: 'Password', required: true },
    { type: 'profile-image', name: 'photo', label: 'Photo' },
  ];

  userTableConfig: DataTableConfig = {
    onAdd: () => this.openCreate(),
    columns: [
      { key: 'id', label: 'User HID' },
      { key: 'username', label: 'Username' },
      { key: 'firstName', label: 'First Name' },
      { key: 'lastName', label: 'Last Name' },
      { key: 'email', label: 'Email' },
      { key: 'enabled', label: 'Enabled', type: 'boolean' },
    ],
    rowActions: [
      {
        label: 'Enable',
        icon: 'fa-check',
        action: (row) => this.enable(row),
        color: 'success',
      },
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
    this.selectedUserId = null;
    this.resetDefaults();
    this.showUserModal = true;
  }

  openEdit(row: any) {
    this.isEdit = true;
    this.selectedUserId = row?.id ?? null;
    this.userFields = this.userFields.map((f) => ({
      ...f,
      defaultValue: row?.[f.name] ?? null,
    }));
    this.showUserModal = true;
  }

  closeModal() {
    this.showUserModal = false;
  }

  onSubmit = () => {
    this.showUserModal = false;
    this.componentService.revalidate('users-table');
  };

  get actionUrl() {
    if (this.isEdit && this.selectedUserId) {
      return `/users/${this.selectedUserId}`;
    }
    return '/users';
  }

  get method() {
    return this.isEdit ? 'PUT' : 'POST';
  }

  private resetDefaults() {
    this.userFields = this.userFields.map((f) => ({ ...f, defaultValue: null }));
  }

  enable(row: any) {
    if (!row?.id) return;
    this.componentService
      .request('PATCH', `/users/${row.id}/enable`, {})
      .subscribe({ next: () => this.componentService.revalidate('users-table') });
  }
}
