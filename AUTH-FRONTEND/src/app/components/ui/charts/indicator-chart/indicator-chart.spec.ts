import { ComponentFixture, TestBed } from '@angular/core/testing';

import { IndicatorChart } from './indicator-chart';

describe('IndicatorChart', () => {
  let component: IndicatorChart;
  let fixture: ComponentFixture<IndicatorChart>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [IndicatorChart]
    })
    .compileComponents();

    fixture = TestBed.createComponent(IndicatorChart);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
