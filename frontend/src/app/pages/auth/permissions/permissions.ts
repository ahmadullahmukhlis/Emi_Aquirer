import { Component, inject } from '@angular/core';
import { DynamicFormBuilder } from '../../../components/ui/dynamic-form-builder/dynamic-form-builder';
import { Datatable } from '../../../components/ui/datatable/datatable';
import { Modal } from '../../../components/ui/modal/modal';
import { DynamicField } from '../../../models/fomrBuilderModel';
import { DataTableConfig } from '../../../models/datatable.model';
import { ApiService } from '../../../services/api/api.service';
import { ComponentService } from '../../../services/genral/component.service';

@Component({
  selector: 'app-permissions',
  standalone: true,
  imports: [DynamicFormBuilder, Datatable, Modal],
  templateUrl: './permissions.html',
  styleUrl: './permissions.css',
})
export class Permissions {
  private api = inject(ApiService);
  private componentService = inject(ComponentService);

  showModal = false;
  isEdit = false;
  selectedId: number | null = null;

  fields: DynamicField[] = [
    { type: 'text', name: 'name', label: 'Display Name', required: true },
    { type: 'text', name: 'permission', label: 'Permission String', required: true },
    {
      type: 'number',
      name: 'permissionGroupId',
      label: 'Permission Group ID (optional)',
    },
  ];

  tableConfig: DataTableConfig = {
    onAdd: () => this.openCreate(),
    columns: [
      { key: 'id', label: 'ID' },
      { key: 'name', label: 'Name' },
      { key: 'permission', label: 'Permission' },
    ],
    rowActions: [
      {
        label: 'Edit',
        icon: 'fa-edit',
        action: (row) => this.openEdit(row),
        color: 'primary',
      },
      {
        label: 'Delete',
        icon: 'fa-trash',
        action: (row) => this.delete(row),
        color: 'danger',
        confirm: {
          title: 'Delete Permission',
          message: 'This will permanently delete the permission.',
        },
      },
    ],
  };

  openCreate() {
    this.isEdit = false;
    this.selectedId = null;
    this.resetDefaults();
    this.showModal = true;
  }

  openEdit(row: any) {
    this.isEdit = true;
    this.selectedId = row?.id ?? null;
    this.fields = this.fields.map((f) => ({ ...f, defaultValue: row?.[f.name] ?? null }));
    this.showModal = true;
  }

  closeModal() {
    this.showModal = false;
  }

  submit = (payload: any) => {
    const finalPayload = {
      name: payload.name,
      permission: payload.permission,
      permissionGroupId: payload.permissionGroupId ? Number(payload.permissionGroupId) : null,
    };

    if (this.isEdit && this.selectedId) {
      this.api.put(`/permissions/${this.selectedId}`, finalPayload).subscribe({
        next: () => {
          this.showModal = false;
          this.componentService.revalidate('permissions-table');
        },
      });
      return;
    }
    this.api.post('/permissions', finalPayload).subscribe({
      next: () => {
        this.showModal = false;
        this.componentService.revalidate('permissions-table');
      },
    });
  };

  delete(row: any) {
    if (!row?.id) return;
    this.api.delete(`/permissions/${row.id}`).subscribe({
      next: () => this.componentService.revalidate('permissions-table'),
    });
  }

  private resetDefaults() {
    this.fields = this.fields.map((f) => ({ ...f, defaultValue: null }));
  }
}
