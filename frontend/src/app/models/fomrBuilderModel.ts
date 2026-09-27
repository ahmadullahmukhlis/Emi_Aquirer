export type FieldType =
  | 'text'
  | 'number'
  | 'password'
  | 'select'
  | 'multi-select'
  | 'server-select'
  | 'radio'
  | 'file'
  | 'date'
  | 'textarea'
  | 'editor'
  | 'checkbox'
  | 'switch'
  | 'div'
  | 'file-upload'
  | 'checkbox-group'
  | 'profile-image'
  | 'repeater';

export interface DynamicField {
  type: FieldType;

  name: string;
  label: string;

  defaultValue?: any;
  disabled?: boolean;
  required?: boolean;

  className?: string;

  options?: any[];
  placeholder?: string;

  /* conditional show */
  show?: (values: any) => boolean;

  /* validation */
  min?: number;
  max?: number;
  minLength?: number;
  maxLength?: number;
  pattern?: string;

  /* server select */
  url?: string;
  optionLabel?: string;
  optionValue?: string;
  multiple?: boolean;
  form?: {
    className?: string;
    submitAreaClassName?: string;
    fields: DynamicField[];
  };

  /* mapping */
  changeValue?: string;
  onSelect?: (row: any) => void;

  onChange?: (value: any) => void;
}
