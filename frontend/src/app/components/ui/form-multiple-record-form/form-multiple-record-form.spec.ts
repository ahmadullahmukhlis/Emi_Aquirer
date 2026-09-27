import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FormMultipleRecordForm } from './form-multiple-record-form';

describe('FormMultipleRecordForm', () => {
  let component: FormMultipleRecordForm;
  let fixture: ComponentFixture<FormMultipleRecordForm>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [FormMultipleRecordForm]
    })
    .compileComponents();

    fixture = TestBed.createComponent(FormMultipleRecordForm);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
