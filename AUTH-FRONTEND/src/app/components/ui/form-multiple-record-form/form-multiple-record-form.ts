import {
  Component,
  Input,
  Output,
  EventEmitter,
  OnChanges,
  SimpleChanges,
  ViewChild,
  ViewContainerRef,
  AfterViewInit,
} from '@angular/core';

@Component({
  selector: 'app-form-multiple-record-form',
  standalone: true,
  templateUrl: './form-multiple-record-form.html', // using HTML file
  styleUrls: ['./form-multiple-record-form.css'],
})
export class FormMultipleRecordForm implements OnChanges, AfterViewInit {
  @Input() form: any;
  @Input() record: any | null = null;
  @Output() formSubmitted = new EventEmitter<any>();

  @ViewChild('container', { read: ViewContainerRef, static: true })
  container!: ViewContainerRef;

  ngAfterViewInit() {
    this.loadDynamicComponent();
  }

  ngOnChanges(changes: SimpleChanges) {
    if (this.container) {
      this.loadDynamicComponent();
    }
  }

  private async loadDynamicComponent() {
    if (!this.form?.fields) return;

    // Lazy load like Vue's defineAsyncComponent
    const { DynamicFormBuilder } = await import('../dynamic-form-builder/dynamic-form-builder');

    // Clear previous component
    this.container.clear();

    // Create dynamic component
    const cmpRef = this.container.createComponent(DynamicFormBuilder);

    // Set inputs
    cmpRef.setInput(
      'fields',
      this.form.fields.map((f: any) => ({
        ...f,
        defaultValue: this.record ? this.record[f.name] : f.value,
      })),
    );
    cmpRef.setInput('className', this.form.className);
    cmpRef.setInput('submitAreaClassName', this.form.submitAreaClassName);

    // Subscribe to output
    cmpRef.instance.formSubmitted.subscribe((values: any) => {
      this.formSubmitted.emit(values);
    });
  }
}
