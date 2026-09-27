import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MultiSelected } from './multi-selected';

describe('MultiSelected', () => {
  let component: MultiSelected;
  let fixture: ComponentFixture<MultiSelected>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MultiSelected]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MultiSelected);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
