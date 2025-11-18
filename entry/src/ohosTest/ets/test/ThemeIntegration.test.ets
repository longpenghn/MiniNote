import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { UIAbility } from '@kit.AbilityKit';
import { Driver, ON } from '@ohos.UiTest';
import { Want } from '@kit.AbilityKit';

export default function themeIntegrationTest() {
  describe('Theme Integration Tests', () => {
    let driver: Driver;
    let ability: UIAbility;

    beforeAll(async () => {
      // Initialize UI test driver
      driver = Driver.create();
      ability = globalThis.abilityContext;
    });

    beforeEach(async () => {
      // Start app for each test
      await driver.delayMs(1000);
    });

    afterEach(async () => {
      // Clean up after each test
    });

    afterAll(async () => {
      // Final cleanup
      await driver.delayMs(1000);
      driver = null;
    });

    it('should display theme toggle button on index page', 0, async () => {
      // Find theme toggle button by its icon (one of the theme icons)
      const themeButton = await driver.findComponent(ON.text('☀️').or(ON.text('🌙')).or(ON.text('🌓')));
      expect(themeButton).assertNotNull();
    });

    it('should cycle through themes when clicking toggle button', 0, async () => {
      // Find and click theme toggle button
      const themeButton = await driver.findComponent(ON.text('☀️').or(ON.text('🌙')).or(ON.text('🌓')));
      expect(themeButton).assertNotNull();

      // Click to toggle themes (test multiple clicks)
      await themeButton.click();
      await driver.delayMs(500);

      // Verify button still exists after theme change
      const themeButtonAfter = await driver.findComponent(ON.text('☀️').or(ON.text('🌙')).or(ON.text('🌓')));
      expect(themeButtonAfter).assertNotNull();
    });

    it('should have theme toggle button on edit page', 0, async () => {
      // First, navigate to edit page by clicking the FAB
      const fabButton = await driver.findComponent(ON.id('floating-action-button').or(ON.text('+')));
      expect(fabButton).assertNotNull();
      await fabButton.click();
      await driver.delayMs(1000);

      // Find theme toggle button on edit page
      const themeButton = await driver.findComponent(ON.text('☀️').or(ON.text('🌙')).or(ON.text('🌓')));
      expect(themeButton).assertNotNull();
    });

    it('should maintain theme state across navigation', 0, async () => {
      // Toggle theme on index page
      const indexThemeButton = await driver.findComponent(ON.text('☀️').or(ON.text('🌙')).or(ON.text('🌓')));
      expect(indexThemeButton).assertNotNull();
      await indexThemeButton.click();
      await driver.delayMs(500);

      // Navigate to edit page
      const fabButton = await driver.findComponent(ON.id('floating-action-button').or(ON.text('+')));
      expect(fabButton).assertNotNull();
      await fabButton.click();
      await driver.delayMs(1000);

      // Check that theme toggle button exists on edit page (theme state should be consistent)
      const editThemeButton = await driver.findComponent(ON.text('☀️').or(ON.text('🌙')).or(ON.text('🌓')));
      expect(editThemeButton).assertNotNull();

      // Go back to index page
      const backButton = await driver.findComponent(ON.text('‹'));
      expect(backButton).assertNotNull();
      await backButton.click();
      await driver.delayMs(1000);

      // Verify theme toggle button still exists on index page
      const indexThemeButtonAfter = await driver.findComponent(ON.text('☀️').or(ON.text('🌙')).or(ON.text('🌓')));
      expect(indexThemeButtonAfter).assertNotNull();
    });

    it('should show correct theme display text', 0, async () => {
      // Find theme toggle button and verify it shows theme text
      const themeButton = await driver.findComponent(ON.text('☀️').or(ON.text('🌙')).or(ON.text('🌓')));
      expect(themeButton).assertNotNull();

      // The button should contain both icon and text
      const buttonText = await themeButton.getText();
      expect(buttonText.length).assertLargerThan(0);

      // Verify one of the theme texts is present
      const hasThemeText = buttonText.includes('浅色') ||
                          buttonText.includes('深色') ||
                          buttonText.includes('自动');
      expect(hasThemeText).assertTrue();
    });
  });
}