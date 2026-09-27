import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SingleSelect } from './single-select';

describe('SingleSelect', () => {
  let component: SingleSelect;
  let fixture: ComponentFixture<SingleSelect>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SingleSelect]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SingleSelect);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
