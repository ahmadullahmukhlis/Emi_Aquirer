import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DynamicFormBuilder } from './dynamic-form-builder';

describe('DynamicFormBuilder', () => {
  let component: DynamicFormBuilder;
  let fixture: ComponentFixture<DynamicFormBuilder>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DynamicFormBuilder]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DynamicFormBuilder);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
