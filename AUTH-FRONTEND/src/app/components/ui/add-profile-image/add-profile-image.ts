import { Component, forwardRef, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NG_VALUE_ACCESSOR, ControlValueAccessor } from '@angular/forms';
import { ImageCroppedEvent, ImageCropperComponent } from 'ngx-image-cropper';

@Component({
  selector: 'app-add-profile-image',
  standalone: true,
  imports: [CommonModule, FormsModule, ImageCropperComponent],
  templateUrl: './add-profile-image.html',
  styleUrls: ['./add-profile-image.css'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => AddProfileImage),
      multi: true,
    },
  ],
})
export class AddProfileImage implements ControlValueAccessor {
  @Input() disabled: boolean = false;
  @Output() valueChange = new EventEmitter<File | string>();

  imageFile: File | null = null;
  preview: string | ArrayBuffer | null = null;

  showCropper: boolean = false;
  imageChangedEvent: any = null;

  private onChange: any = () => {};
  private onTouched: any = () => {};

  writeValue(value: any): void {
    if (!value) {
      this.imageFile = null;
      this.preview = null;
      return;
    }

    if (typeof value === 'string') {
      this.preview = value;
      this.imageFile = null;
    } else if (value instanceof File) {
      this.imageFile = value;
      const reader = new FileReader();
      reader.onload = () => (this.preview = reader.result);
      reader.readAsDataURL(value);
    }
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

  openFileDialog(input: HTMLInputElement) {
    if (!this.disabled) input.click();
  }

  // Handle file selection
  onFileSelected(event: any) {
    const file: File = event.target.files[0];
    if (!file) return;

    this.imageChangedEvent = event; // Needed for cropper
    this.showCropper = true;
  }

  // Cropper emits the cropped image
  imageCropped(event: ImageCroppedEvent) {
    if (!event.base64) return;

    this.preview = event.base64;
    const file = this.base64ToFile(event.base64, this.imageFile?.name || 'cropped.png');
    this.imageFile = file;

    this.onChange(file);
    this.onTouched();
    this.valueChange.emit(file);
  }

  // Cropper finished
  cropperDone() {
    if (this.imageChangedEvent) {
      // User didn't move cropper, but we can use original file
      const file = this.imageChangedEvent.target.files[0];
      this.preview = URL.createObjectURL(file);
      this.imageFile = file;

      // Emit to parent
      this.onChange(file);
      this.onTouched();
      this.valueChange.emit(file);
    } else if (this.imageFile) {
      // Already cropped, just emit
      this.onChange(this.imageFile);
      this.onTouched();
      this.valueChange.emit(this.imageFile);
    }

    // Close the cropper modal
    this.showCropper = false;
    this.imageChangedEvent = null;
  }

  cropperCancel() {
    this.showCropper = false;
    this.imageChangedEvent = null;
    // Optional: reset preview/file if you want to discard
    this.preview = this.imageFile ? this.preview : null;
  }

  // Utility: Convert base64 to File
  private base64ToFile(data: string, filename: string): File {
    const arr = data.split(',');
    const mime = arr[0].match(/:(.*?);/)![1];
    const bstr = atob(arr[1]);
    let n = bstr.length;
    const u8arr = new Uint8Array(n);
    while (n--) u8arr[n] = bstr.charCodeAt(n);
    return new File([u8arr], filename, { type: mime });
  }
}
