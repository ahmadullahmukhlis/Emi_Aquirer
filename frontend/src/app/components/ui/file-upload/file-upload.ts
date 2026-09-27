import {
  Component,
  EventEmitter,
  Input,
  Output,
  ChangeDetectorRef,
  OnDestroy,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subscription, Subject } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

@Component({
  selector: 'app-file-upload',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './file-upload.html',
  styleUrls: ['./file-upload.css'],
})
export class FileUpload implements OnDestroy {
  @Input() multiple: boolean = false;
  @Input() maxSizeMB: number = 20;
  @Input() acceptedTypes: string = '*/*';
  @Output() fileChange = new EventEmitter<File[]>();

  isDragging = false;
  selectedFiles: File[] = [];
  previews: { file: File; url: string | null; loading: boolean; error?: string }[] = [];

  private previewQueue = new Subject<File>();
  private subscriptions: Subscription[] = [];

  constructor(private cdr: ChangeDetectorRef) {
    const sub = this.previewQueue
      .pipe(debounceTime(20))
      .subscribe((file) => this.generatePreview(file));
    this.subscriptions.push(sub);
  }

  ngOnDestroy() {
    this.subscriptions.forEach((s) => s.unsubscribe());
    this.clearAllPreviews();
  }

  onDragOver(event: DragEvent) {
    event.preventDefault();
    this.isDragging = true;
  }

  onDragLeave(event: DragEvent) {
    event.preventDefault();
    this.isDragging = false;
  }

  onDrop(event: DragEvent) {
    event.preventDefault();
    this.isDragging = false;
    if (!event.dataTransfer?.files) return;
    this.processFiles(Array.from(event.dataTransfer.files));
  }

  onFileSelect(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files) return;
    this.processFiles(Array.from(input.files));
    input.value = ''; // reset input so same file can be re-uploaded
  }

  private processFiles(files: File[]) {
    const validFiles: File[] = [];
    const errors: string[] = [];

    files.forEach((file) => {
      // File size check
      if (file.size > this.maxSizeMB * 1024 * 1024) {
        errors.push(`${file.name} exceeds ${this.maxSizeMB}MB`);
        return;
      }

      // File type check
      if (this.acceptedTypes !== '*/*') {
        const accepted = this.acceptedTypes.split(',').map((t) => t.trim());
        const fileType = file.type || '';
        const fileName = file.name.toLowerCase();

        const isValid = accepted.some((type) => {
          if (type.endsWith('/*')) return fileType.startsWith(type.split('/')[0] + '/');
          if (type.startsWith('.')) return fileName.endsWith(type);
          return fileType === type;
        });

        if (!isValid) {
          errors.push(`${file.name} type not allowed`);
          return;
        }
      }

      validFiles.push(file);
    });

    if (errors.length) alert(errors.join('\n'));

    if (validFiles.length) {
      if (this.multiple) {
        // Keep existing files and append new ones
        const combined = [...this.selectedFiles, ...validFiles];
        this.selectedFiles = combined.slice(0, 20); // limit to 20 files
      } else {
        this.selectedFiles = [validFiles[0]];
      }

      // Initialize preview objects immediately
      validFiles.forEach((file) => {
        this.previews.push({
          file,
          url: null,
          loading: file.type.startsWith('image/'),
          error: undefined,
        });
        this.previewQueue.next(file);
      });

      this.fileChange.emit(this.selectedFiles);
    }
  }

  private queuePreviews() {
    this.clearAllPreviews();

    this.previews = this.selectedFiles.map((f) => ({ file: f, url: null, loading: true }));
    this.selectedFiles.forEach((f) => this.previewQueue.next(f));
    this.cdr.detectChanges();
  }

  private clearAllPreviews() {
    this.previews.forEach((p) => p.url && p.url.startsWith('blob:') && URL.revokeObjectURL(p.url));
    this.previews = [];
  }

  private generatePreview(file: File) {
    const index = this.previews.findIndex((p) => p.file === file);
    if (index === -1) return;

    if (file.type.startsWith('image/')) {
      const url = URL.createObjectURL(file);
      const img = new Image();
      img.onload = () => {
        this.previews[index] = { ...this.previews[index], url, loading: false };
        this.cdr.detectChanges();
      };
      img.onerror = () => {
        URL.revokeObjectURL(url);
        this.previews[index] = {
          ...this.previews[index],
          url: null,
          loading: false,
          error: 'Failed',
        };
        this.cdr.detectChanges();
      };
      img.src = url;
    } else {
      // Non-image: show generic icon immediately
      this.previews[index] = { ...this.previews[index], loading: false, url: null };
      this.cdr.detectChanges();
    }
  }

  removeFile(index: number) {
    const removedPreview = this.previews[index];
    if (!removedPreview) return;

    // Revoke blob URL if image
    if (removedPreview.url && removedPreview.url.startsWith('blob:')) {
      URL.revokeObjectURL(removedPreview.url);
    }

    // Remove from both arrays safely
    const removedFile = removedPreview.file;

    this.previews = this.previews.filter((_, i) => i !== index);
    this.selectedFiles = this.selectedFiles.filter((f) => f !== removedFile);

    // 🔥 Always emit updated list to parent
    this.fileChange.emit([...this.selectedFiles]);

    this.cdr.detectChanges();
  }

  clearAllFiles() {
    this.clearAllPreviews();
    this.selectedFiles = [];
    this.fileChange.emit([]);
  }

  formatFileSize(bytes: number) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  getTotalSize() {
    const total = this.selectedFiles.reduce((sum, f) => sum + f.size, 0);
    return this.formatFileSize(total);
  }
}
