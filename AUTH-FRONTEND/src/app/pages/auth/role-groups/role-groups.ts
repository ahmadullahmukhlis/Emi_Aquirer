import { Component, inject } from '@angular/core';
import { DynamicFormBuilder } from '../../../components/ui/dynamic-form-builder/dynamic-form-builder';
import { Datatable } from '../../../components/ui/datatable/datatable';
import { Modal } from '../../../components/ui/modal/modal';
import { DynamicField } from '../../../models/fomrBuilderModel';
import { DataTableConfig } from '../../../models/datatable.model';
import { ApiService } from '../../../services/api/api.service';
import { ComponentService } from '../../../services/genral/component.service';

@Component({
  selector: 'app-role-groups',
  standalone: true,
  imports: [DynamicFormBuilder, Datatable, Modal],
  templateUrl: './role-groups.html',
  styleUrl: './role-groups.css',
})
export class RoleGroups {
  private api = inject(ApiService);
  private componentService = inject(ComponentService);

  showModal = false;
  isEdit = false;
  selectedId: number | null = null;

  fields: DynamicField[] = [{ type: 'text', name: 'name', label: 'Role Group Name', required: true }];

  tableConfig: DataTableConfig = {
    onAdd: () => this.openCreate(),
    columns: [
      { key: 'id', label: 'ID' },
      { key: 'name', label: 'Name' },
      { key: 'clientName', label: 'Client' },
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
          title: 'Delete Role Group',
          message: 'This will permanently delete the role group.',
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
    const finalPayload = { name: payload.name };
    if (this.isEdit && this.selectedId) {
      this.api.put(`/role-groups/${this.selectedId}`, finalPayload).subscribe({
        next: () => {
          this.showModal = false;
          this.componentService.revalidate('role-groups-table');
        },
      });
      return;
    }
    this.api.post('/role-groups', finalPayload).subscribe({
      next: () => {
        this.showModal = false;
        this.componentService.revalidate('role-groups-table');
      },
    });
  };

  delete(row: any) {
    if (!row?.id) return;
    this.api.delete(`/role-groups/${row.id}`).subscribe({
      next: () => this.componentService.revalidate('role-groups-table'),
    });
  }

  private resetDefaults() {
    this.fields = this.fields.map((f) => ({ ...f, defaultValue: null }));
  }
}
