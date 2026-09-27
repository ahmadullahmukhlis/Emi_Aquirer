import { ComponentFixture, TestBed } from '@angular/core/testing';

import { LinearChart } from './linear-chart';

describe('LinearChart', () => {
  let component: LinearChart;
  let fixture: ComponentFixture<LinearChart>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [LinearChart]
    })
    .compileComponents();

    fixture = TestBed.createComponent(LinearChart);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
