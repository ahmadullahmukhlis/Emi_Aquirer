import { Component, inject } from '@angular/core';
import { DynamicFormBuilder } from '../../../components/ui/dynamic-form-builder/dynamic-form-builder';
import { Datatable } from '../../../components/ui/datatable/datatable';
import { Modal } from '../../../components/ui/modal/modal';
import { DynamicField } from '../../../models/fomrBuilderModel';
import { DataTableConfig } from '../../../models/datatable.model';
import { ApiService } from '../../../services/api/api.service';
import { ComponentService } from '../../../services/genral/component.service';

@Component({
  selector: 'app-roles',
  standalone: true,
  imports: [DynamicFormBuilder, Datatable, Modal],
  templateUrl: './roles.html',
  styleUrl: './roles.css',
})
export class Roles {
  private api = inject(ApiService);
  private componentService = inject(ComponentService);

  showModal = false;
  isEdit = false;
  selectedId: number | null = null;

  fields: DynamicField[] = [
    { type: 'text', name: 'name', label: 'Role Name', required: true },
    { type: 'number', name: 'roleGroupId', label: 'Role Group ID (optional)' },
    {
      type: 'textarea',
      name: 'permissionIds',
      label: 'Permission IDs (comma or newline separated)',
    },
  ];

  tableConfig: DataTableConfig = {
    onAdd: () => this.openCreate(),
    columns: [
      { key: 'id', label: 'ID' },
      { key: 'name', label: 'Name' },
      { key: 'roleGroup', label: 'Group' },
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
          title: 'Delete Role',
          message: 'This will permanently delete the role.',
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
    const permissionIds = this.splitList(payload.permissionIds).map((v) => Number(v));
    const finalPayload = {
      name: payload.name,
      roleGroupId: payload.roleGroupId ? Number(payload.roleGroupId) : null,
      permissionIds,
    };

    if (this.isEdit && this.selectedId) {
      this.api.put(`/roles/${this.selectedId}`, finalPayload).subscribe({
        next: () => {
          this.showModal = false;
          this.componentService.revalidate('roles-table');
        },
      });
      return;
    }
    this.api.post('/roles', finalPayload).subscribe({
      next: () => {
        this.showModal = false;
        this.componentService.revalidate('roles-table');
      },
    });
  };

  delete(row: any) {
    if (!row?.id) return;
    this.api.delete(`/roles/${row.id}`).subscribe({
      next: () => this.componentService.revalidate('roles-table'),
    });
  }

  private splitList(value: any): string[] {
    if (!value) return [];
    if (Array.isArray(value)) return value;
    return value
      .split(/[\n,]/)
      .map((v: string) => v.trim())
      .filter((v: string) => v.length > 0);
  }

  private resetDefaults() {
    this.fields = this.fields.map((f) => ({ ...f, defaultValue: null }));
  }
}
