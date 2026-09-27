import { chromium } from '@playwright/test';
import assert from 'node:assert/strict';
import {mkdirSync} from 'node:fs';
const browser=await chromium.launch({channel:'chrome',headless:true});
const page=await browser.newPage({viewport:{width:1440,height:1000}});
const errors=[];page.on('pageerror',e=>errors.push(e.message));
const email=`browser-${Date.now()}@example.test`;
try{
await page.goto('http://localhost:8082');
await page.getByRole('heading',{name:'Sign in to your account'}).waitFor();
assert.equal(await page.locator('header').count(),0);
await page.getByRole('button',{name:'Create account',exact:true}).click();
await page.getByLabel('Full name').fill('Browser Test');await page.getByLabel('Email address').fill(email);await page.getByLabel('Password',{exact:true}).fill('Browser-Test-Password-123!');await page.getByRole('button',{name:'Create account',exact:true}).click();
await page.getByRole('button',{name:'Create application'}).click();await page.getByLabel('Application name').fill('Browser shop');await page.locator('dialog').getByRole('button',{name:'Create application'}).click();
await page.getByRole('heading',{name:'Overview',exact:true}).waitFor();
await page.getByRole('link',{name:'API keys',exact:false}).click();await page.getByRole('button',{name:'Create secret key'}).click();await page.getByRole('heading',{name:'Save your secret'}).waitFor();assert.match(await page.locator('#secret-value').textContent(),/^sk_test_/);await page.getByRole('button',{name:'Close',exact:true}).click();
await page.getByRole('link',{name:'Payments',exact:false}).click();await page.getByRole('button',{name:'Test purchase'}).click();await page.getByLabel('Order reference').fill('browser-order');await page.getByRole('button',{name:'Submit test purchase'}).click();await page.getByRole('heading',{name:'Payment details'}).waitFor();await page.locator('dialog .badge.approved').waitFor({timeout:20000});await page.getByRole('button',{name:'Close',exact:true}).click();
await page.getByRole('link',{name:'Overview',exact:false}).click();await page.getByRole('heading',{name:'Overview',exact:true}).waitFor();await page.locator('.metrics').waitFor();mkdirSync('../.local-data/screenshots',{recursive:true});await page.screenshot({path:'../.local-data/screenshots/portal-overview.png',fullPage:true});
for(const name of ['Payments','Applications','API keys','Webhooks','Event logs','Business verification','Integration guide','Settings']){await page.getByRole('link',{name,exact:false}).click();await page.getByRole('heading',{name,exact:true}).waitFor();assert.equal(await page.getByRole('heading',{name:'Couldn’t load this page'}).count(),0);}
await page.setViewportSize({width:390,height:844});await page.getByRole('link',{name:'Payments',exact:false}).click();await page.getByRole('heading',{name:'Payments',exact:true}).waitFor();await page.screenshot({path:'../.local-data/screenshots/portal-mobile.png',fullPage:true});
assert.deepEqual(errors,[]);console.log('PASS: registration → app → key → Gateway-approved purchase → dashboard, all pages, mobile viewport; no browser errors');
}finally{await browser.close();}
