import {
  Component,
  Input,
  Output,
  EventEmitter,
  OnInit,
  OnChanges,
  SimpleChanges,
  inject,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormMultipleRecordForm } from '../form-multiple-record-form/form-multiple-record-form';
import { Modal } from '../modal/modal';
import { ToastService } from '../../../services/genral/tost.service';

@Component({
  selector: 'app-multiple-record',
  standalone: true,
  imports: [CommonModule, Modal, FormMultipleRecordForm],
  templateUrl: './multiple-record.html',
  styleUrls: ['./multiple-record.css'],
})
export class MultipleRecord implements OnInit, OnChanges {
  @Input() defaultValues: any[] = [];
  @Input() label: string | undefined;
  @Input() field: any;
  @Input() errorMessage!: string;

  @Output() onChange = new EventEmitter<any[]>();

  values: any[] = [];

  // Modal States
  modalVisible = false;
  selectedRecord: any = null;
  private ToastService = inject(ToastService);

  ngOnInit(): void {
    this.initializeValues();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['defaultValues']) {
      this.initializeValues();
    }
  }

  private initializeValues() {
    this.values = Array.isArray(this.defaultValues) ? [...this.defaultValues] : [];
  }

  generateRandomId(): string {
    return Math.random().toString(36).substring(2, 15);
  }

  /* =========================
     MODAL CONTROL
  ========================== */

  openAddModal() {
    this.selectedRecord = null;
    this.modalVisible = true;
  }

  openEditModal(record: any) {
    this.selectedRecord = { ...record };
    this.modalVisible = true;
  }

  closeModal() {
    this.modalVisible = false;
    this.selectedRecord = null;
  }

  /* =========================
     FORM SUBMIT HANDLERS
  ========================== */

  handleFormSubmit(formValues: any) {
    if (this.selectedRecord) {
      this.updateRecord(formValues);
    } else {
      this.addRecord(formValues);
    }
  }

  private addRecord(formValues: any) {
    const newRecord = { id: this.generateRandomId(), ...formValues };
    this.values = [...this.values, newRecord];
    this.onChange.emit(this.values);
    this.closeModal();
  }

  private updateRecord(formValues: any) {
    const index = this.values.findIndex((v) => v.id === this.selectedRecord.id);
    if (index > -1) {
      this.values[index] = { id: this.selectedRecord.id, ...formValues };
      this.values = [...this.values]; // trigger change detection
      this.onChange.emit(this.values);
    }
    this.closeModal();
  }

  handleDelete(id: string) {
    this.ToastService.confirmDelete({ name: 'Record' }, () => {
      this.deleteRecord(id);
    });
  }

  private deleteRecord(id: string) {
    this.values = this.values.filter((v) => v.id !== id);
    this.onChange.emit(this.values);
  }
}
