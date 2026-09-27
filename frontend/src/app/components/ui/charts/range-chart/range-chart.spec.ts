import { ComponentFixture, TestBed } from '@angular/core/testing';

import { RangeChart } from './range-chart';

describe('RangeChart', () => {
  let component: RangeChart;
  let fixture: ComponentFixture<RangeChart>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [RangeChart]
    })
    .compileComponents();

    fixture = TestBed.createComponent(RangeChart);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
