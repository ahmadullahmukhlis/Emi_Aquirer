import { Component, EventEmitter, inject, Input, Output, forwardRef, OnInit } from '@angular/core';
import { MultiSelectModule } from 'primeng/multiselect';
import { ComponentService } from '../../../services/genral/component.service';
import { NG_VALUE_ACCESSOR, ControlValueAccessor, FormsModule } from '@angular/forms';

@Component({
  selector: 'app-multi-selected',
  standalone: true,
  imports: [FormsModule, MultiSelectModule], // 🔹 add FormsModule here!
  templateUrl: './multi-selected.html',
  styleUrls: ['./multi-selected.css'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => MultiSelected),
      multi: true,
    },
  ],
})
export class MultiSelected implements OnInit, ControlValueAccessor {
  @Input() url!: string;
  @Input() optionLabel!: string;
  @Input() optionValue!: string;
  @Input() placeholder: string = 'Select';
  @Input() showClear: boolean = true;
  @Input() isSearable: boolean = true;
  @Input() disabled: boolean = false;
  @Output() valueChange = new EventEmitter<any>();

  options: any[] = [];
  loading = false;

  // internal value for ngModel / formControl
  selected: any[] = [];

  componentService = inject(ComponentService);

  // ControlValueAccessor callbacks
  private onChange: any = () => {};
  private onTouched: any = () => {};

  ngOnInit() {
    if (this.url) this.loadOptions();
  }

  loadOptions() {
    this.loading = true;

    this.componentService.getList(this.url).subscribe({
      next: (res) => {
        this.options = res;
        this.loading = false;

        // 🔹 if form already has value (edit mode), keep selected
        if (this.selected && this.selected.length > 0) {
          this.selected = this.selected;
        }
      },
      error: () => (this.loading = false),
    });
  }

  // called by PrimeNG MultiSelect
  onSelectChange(e: any) {
    this.selected = e.value;

    // 🔹 update formControl if used
    this.onChange(this.selected);
    this.onTouched();

    // 🔹 keep valueChange for filters / other uses
    this.valueChange.emit(this.selected);
  }

  // 🔹 ControlValueAccessor methods
  writeValue(value: any): void {
    this.selected = value ?? [];
  }

  registerOnChange(fn: any): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: any): void {
    this.onTouched = fn;
  }

  setDisabledState?(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }
}
