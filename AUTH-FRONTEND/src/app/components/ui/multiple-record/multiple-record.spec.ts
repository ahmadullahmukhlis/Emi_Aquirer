import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MultipleRecord } from './multiple-record';

describe('MultipleRecord', () => {
  let component: MultipleRecord;
  let fixture: ComponentFixture<MultipleRecord>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MultipleRecord]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MultipleRecord);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
