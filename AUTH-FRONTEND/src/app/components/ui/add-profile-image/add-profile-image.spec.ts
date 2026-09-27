import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AddProfileImage } from './add-profile-image';

describe('AddProfileImage', () => {
  let component: AddProfileImage;
  let fixture: ComponentFixture<AddProfileImage>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AddProfileImage]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AddProfileImage);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
