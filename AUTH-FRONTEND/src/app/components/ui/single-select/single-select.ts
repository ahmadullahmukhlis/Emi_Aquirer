import { Component, inject, Input, OnInit, Output, EventEmitter, forwardRef } from '@angular/core';
import { ComponentService } from '../../../services/genral/component.service';
import { FormsModule, NG_VALUE_ACCESSOR, ControlValueAccessor } from '@angular/forms';
import { SelectModule } from 'primeng/select';

@Component({
  selector: 'app-single-select',
  standalone: true,
  imports: [FormsModule, SelectModule],
  templateUrl: './single-select.html',
  styleUrls: ['./single-select.css'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => SingleSelect),
      multi: true,
    },
  ],
})
export class SingleSelect implements OnInit, ControlValueAccessor {
  @Input() url?: string;
  @Input() optionLabel!: string;
  @Input() optionValue!: string;
  @Input() placeholder: string = 'Select';
  @Input() showClear: boolean = true;
  @Input() isSearable: boolean = true;
  @Input() multiple: boolean = false;
  @Input() disabled: boolean = false;

  @Output() valueChange = new EventEmitter<any>();

  options: any[] = [];
  loading = false;

  // Internal value for ngModel / formControl
  selected: any;

  componentService = inject(ComponentService);

  // ControlValueAccessor callbacks
  private onChange: any = () => {};
  private onTouched: any = () => {};

  ngOnInit() {
    if (this.url) this.loadOptions();
  }

  loadOptions() {
    this.loading = true;
    this.componentService.getList(this.url ?? '').subscribe({
      next: (res) => {
        this.options = res;
        this.loading = false;

        // 🔹 If form already has value (edit mode), make sure selected is set
        if (this.selected != null) {
          this.selected = this.selected;
        }
      },
      error: () => (this.loading = false),
    });
  }

  // Called by PrimeNG p-select
  onSelectChange(e: any) {
    this.selected = e.value;

    // 🔹 Update formControl if used
    this.onChange(this.selected);
    this.onTouched();

    // 🔹 Keep valueChange for filters / other uses
    this.valueChange.emit(this.selected);
  }

  // 🔹 ControlValueAccessor methods
  writeValue(value: any): void {
    this.selected = value; // 👈 defaultValue from formControl or edit data
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
