import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MainContent } from './main-content';

describe('MainContent', () => {
  let component: MainContent;
  let fixture: ComponentFixture<MainContent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MainContent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MainContent);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
