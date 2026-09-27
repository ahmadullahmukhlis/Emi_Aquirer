import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

/* PrimeNG */
import { InputTextModule } from 'primeng/inputtext';
import { InputNumberModule } from 'primeng/inputnumber';
import { DatePickerModule } from 'primeng/datepicker';
import { TextareaModule } from 'primeng/textarea';
import { CheckboxModule } from 'primeng/checkbox';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { PasswordModule } from 'primeng/password';
import { ButtonModule } from 'primeng/button';
import { SelectModule } from 'primeng/select';

/* Components */
import { SingleSelect } from '../single-select/single-select';

/* Models */
import { DynamicField } from '../../../models/fomrBuilderModel';

@Component({
  selector: 'app-filter',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    InputTextModule,
    InputNumberModule,
    DatePickerModule,
    TextareaModule,
    CheckboxModule,
    ToggleSwitchModule,
    PasswordModule,
    ButtonModule,
    SelectModule,
    SingleSelect,
  ],
  templateUrl: './filter.html',
  styleUrls: ['./filter.css'],
})
export class Filter implements OnInit {
  @Input({ required: true }) fields: DynamicField[] = [];
  @Input() className: string = '';
  @Output() onFilter = new EventEmitter<any>();
  @Output() valuesChanged = new EventEmitter<any>();
  labelTypes = [
    'text',
    'number',
    'date',
    'textarea',
    'checkbox',
    'switch',
    'select',
    'server-select',
  ];

  form!: FormGroup; // Declare form here

  constructor(private fb: FormBuilder) {}

  ngOnInit() {
    this.form = this.fb.group({});

    this.fields.forEach((field) => {
      this.form.addControl(field.name, this.fb.control(field.changeValue ?? null));
    });

    this.form.valueChanges.subscribe((values) => {
      this.valuesChanged.emit(values);
    });
  }

  handleSelectChange(field: DynamicField, selected: any | any[]) {
    console.log('Selected value:', selected);
    if (field.type === 'multi-select') {
      const values = selected?.map((item: any) =>
        field.changeValue ? item[field.changeValue] : item,
      );
      this.form.get(field.name)?.setValue(values);
    } else {
      const val = field.changeValue ? selected?.[field.changeValue] : selected;
      this.form.get(field.name)?.setValue(val);
    }

    field.onSelect?.(selected);
  }

  applyFilter() {
    this.onFilter.emit(this.form.value);
  }
}
