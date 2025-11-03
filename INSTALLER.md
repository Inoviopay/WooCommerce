# Inovio Payment Gateway - Installation Guide

Comprehensive installation and configuration guide for the Inovio Payment Gateway WooCommerce Plugin.

## Table of Contents

- [Pre-Installation Requirements](#pre-installation-requirements)
- [Installation Methods](#installation-methods)
- [Post-Installation Configuration](#post-installation-configuration)
- [Testing the Integration](#testing-the-integration)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

## Pre-Installation Requirements

### Server Requirements

Before installing the plugin, verify your server meets these requirements:

```bash
# Check PHP version (must be 5.2.4 or higher)
php -v

# Check if cURL extension is installed
php -m | grep curl

# Check if JSON extension is installed
php -m | grep json
```

**Required:**
- WordPress 5.0 or higher
- WooCommerce 3.0 or higher
- PHP 5.2.4 or higher
- PHP cURL extension
- PHP JSON extension
- MySQL 5.6 or higher (or MariaDB 10.0+)
- HTTPS/SSL certificate (production only)

**Optional but Recommended:**
- WooCommerce Subscriptions 2.0+ (for recurring payments)
- WordPress 5.5+ for best compatibility
- PHP 7.4+ for optimal performance

### Inovio Merchant Account

You must have an active Inovio merchant account before installation:

1. Visit https://www.inoviopay.com/
2. Click "Get Started" or "Contact Sales"
3. Complete merchant application
4. Wait for account approval (typically 1-3 business days)
5. Receive your credentials:
   - API Endpoint URL
   - Site ID
   - API Username
   - API Password
   - Product ID(s)

### Backup Your Site

**Always backup before installing new plugins:**

```bash
# Using WP-CLI to backup database
wp db export backup-$(date +%Y%m%d).sql

# Or use a backup plugin like UpdraftPlus, BackupBuddy, etc.
```

## Installation Methods

### Method 1: WordPress Admin Panel (Recommended)

**Step 1: Download the Plugin**
1. Obtain the `inovio-payment-gateway.zip` file from:
   - Inovio support team
   - Your merchant portal
   - GitHub releases (if applicable)

**Step 2: Upload via WordPress Admin**
1. Log in to WordPress admin panel
2. Navigate to **Plugins > Add New**
3. Click **Upload Plugin** button at the top
4. Click **Choose File** and select `inovio-payment-gateway.zip`
5. Click **Install Now**
6. Wait for upload and extraction to complete
7. Click **Activate Plugin**

**Step 3: Verify Installation**
1. Go to **Plugins > Installed Plugins**
2. Confirm "Inovio Payment Gateway WooCommerce Plugin" shows version 4.4.23
3. Status should show "Active"

### Method 2: FTP/SFTP Upload

**Step 1: Extract the Plugin**
```bash
# On your local machine
unzip inovio-payment-gateway.zip
```

**Step 2: Upload via FTP**
1. Connect to your server using FTP client (FileZilla, Cyberduck, etc.)
2. Navigate to: `/wp-content/plugins/`
3. Upload the entire `inovio-payment-gateway` folder
4. Verify all files uploaded successfully

**Step 3: Activate via WordPress**
1. Log in to WordPress admin
2. Go to **Plugins**
3. Find "Inovio Payment Gateway WooCommerce Plugin"
4. Click **Activate**

### Method 3: WP-CLI (Advanced)

**For users with SSH/shell access:**

```bash
# Navigate to WordPress root directory
cd /path/to/wordpress

# Install and activate the plugin
wp plugin install /path/to/inovio-payment-gateway.zip --activate

# Verify installation
wp plugin list | grep inovio

# Expected output:
# inovio-payment-gateway    4.4.23    active
```

### Method 4: Git Clone (Development)

**For developers working from repository:**

```bash
# Navigate to plugins directory
cd /path/to/wordpress/wp-content/plugins/

# Clone the repository
git clone https://github.com/inoviopay/woocommerce-plugin.git inovio-payment-gateway

# Or if using a different repo
cd inovio-payment-gateway
git pull origin main

# Activate via WP-CLI
wp plugin activate inovio-payment-gateway
```

## Post-Installation Configuration

### Database Table Creation

The plugin automatically creates custom tables on activation. Verify:

```sql
-- Connect to MySQL
mysql -u your_username -p your_database

-- Check for Inovio tables
SHOW TABLES LIKE '%inovio_refunded%';

-- Expected output:
-- wp_inovio_refunded
-- wp_ach_inovio_refunded
```

If tables are missing, deactivate and reactivate the plugin.

### Configure Credit Card Gateway

**Step 1: Access Payment Settings**
1. Navigate to **WooCommerce > Settings**
2. Click **Payments** tab
3. Find "Inovio" in the payment methods list
4. Click **Manage** button

**Step 2: Basic Settings**

| Field | Value | Notes |
|-------|-------|-------|
| **Enable Inovio** | ✓ Checked | Enables the payment method |
| **Title** | Credit Card | Shown to customers at checkout |
| **Description** | Pay securely with your credit card | Brief explanation |

**Step 3: API Credentials**

| Field | Example | Where to Find |
|-------|---------|---------------|
| **API Endpoint** | `https://gateway.inoviopay.com/payment/pmt_service.cfm` | Provided by Inovio support |
| **Site ID** | `MERCHANT123` | Merchant portal or welcome email |
| **Request Username** | `api_user_prod` | Merchant portal > Settings > API |
| **Request Password** | `your_secure_password` | Merchant portal > Settings > API |
| **Product ID** | `PROD001` | Product configuration in portal |

**Step 4: Advanced Options**

```
Debug Mode: [ ] Disabled (for production)
            [✓] Enabled (for testing only)

Product Quantity Restriction: Leave blank or set maximum per-product quantity

Additional Parameters: Advanced users can add custom fields
```

**Step 5: Save**
Click **Save changes** at the bottom of the page.

### Configure ACH Gateway

Repeat the same steps for the ACH payment method:

1. Go to **WooCommerce > Settings > Payments**
2. Find "Inovio ACH"
3. Click **Manage**
4. Configure with same credentials as credit card gateway
5. Customize title/description for bank payments:
   - Title: "Bank Account (ACH)"
   - Description: "Pay directly from your checking or savings account"

### Configure Checkout Settings

**Terms of Service PDF**

The plugin includes a default Terms of Service PDF:
- Location: `wp-content/plugins/inovio-payment-gateway/assets/pdf/TOS_ENG.pdf`
- To customize:
  1. Replace the PDF file with your own
  2. Keep the same filename or update in main plugin file
  3. Ensure PDF is readable (644 permissions)

**Subscription Disclosures**

For subscription products, disclosure text is auto-generated:
```
"After {interval}{period}, membership renews at {currency}{price}
every {interval}{period} until cancelled"
```

This is automatically displayed when subscription products are in cart.

### Set File Permissions

**Recommended permissions:**

```bash
# Navigate to plugin directory
cd wp-content/plugins/inovio-payment-gateway

# Set directory permissions
find . -type d -exec chmod 755 {} \;

# Set file permissions
find . -type f -exec chmod 644 {} \;

# Ensure WordPress can write logs (if debug enabled)
chmod 755 ../../../wp-content/uploads/wc-logs/
```

## Testing the Integration

### Test Mode Configuration

**Step 1: Enable Test Mode**
1. In payment gateway settings, enable **Debug Mode**
2. Use Inovio test credentials (if provided)
3. Or request test account from Inovio support

**Step 2: Test Credentials**

Typical test credentials (verify with Inovio):
```
API Endpoint: https://gateway-test.inoviopay.com/payment/pmt_service.cfm
Site ID: TESTBANK
Username: test_user
Password: test_password
```

**Step 3: Test Cards**

| Card Type | Number | Expiry | CVV | Expected Result |
|-----------|--------|--------|-----|-----------------|
| Visa | 4111111111111111 | 12/25 | 123 | Approved |
| MasterCard | 5555555555554444 | 12/25 | 123 | Approved |
| Decline Test | 4000000000000002 | 12/25 | 123 | Declined |

**Step 4: Process Test Transaction**

1. Add a product to cart
2. Proceed to checkout
3. Fill in billing details
4. Select "Inovio" payment method
5. Enter test card: `4111111111111111`
6. Expiry: `12/25`, CVV: `123`
7. Accept Terms of Service
8. Click **Place Order**

**Step 5: Verify Transaction**

1. Order should complete successfully
2. Check **WooCommerce > Orders** for the new order
3. Order status should be "Processing" or "Completed"
4. Order notes should show: "Billing Direct API Payment completed and Transaction Id: [ID]"
5. Check logs in **WooCommerce > Status > Logs**

### Test Refunds

1. Open the test order
2. Click **Refund** button
3. Enter partial amount (e.g., $5.00)
4. Click **Refund $5.00 via Inovio**
5. Verify refund success in order notes
6. Repeat to test full refund

### Test Subscriptions (if applicable)

**Prerequisites:**
- WooCommerce Subscriptions plugin installed
- Subscription product created

**Test Process:**
1. Create a subscription product:
   - Price: $10/month
   - Sign-up fee: $5 (optional)
2. Purchase the subscription with test card
3. Verify initial payment successful
4. Check subscription created: **WooCommerce > Subscriptions**
5. Wait for scheduled renewal OR trigger manually:
   ```bash
   wp wc subscription renew [subscription_id]
   ```
6. Verify renewal payment processed automatically

## Production Deployment

### Pre-Production Checklist

- [ ] SSL certificate installed and active
- [ ] Production Inovio credentials obtained
- [ ] Test transactions completed successfully
- [ ] Refund process tested
- [ ] Subscription renewals tested (if applicable)
- [ ] Terms of Service PDF customized
- [ ] Privacy Policy updated to mention Inovio
- [ ] Debug mode disabled
- [ ] Error logging configured
- [ ] Full site backup completed

### Switch to Production Credentials

1. Navigate to **WooCommerce > Settings > Payments > Inovio**
2. Update API credentials:
   ```
   API Endpoint: https://gateway.inoviopay.com/payment/pmt_service.cfm
   Site ID: [Your Production Site ID]
   Username: [Production Username]
   Password: [Production Password]
   Product ID: [Production Product ID]
   ```
3. **Disable Debug Mode**
4. Click **Save changes**

### Production Testing

**Process a real transaction with small amount:**
1. Use your own credit card
2. Purchase a low-value item ($1-$5)
3. Verify payment successful
4. Process a refund to test refund functionality
5. Monitor for any errors

### Go-Live Announcement

1. Update website to remove "test mode" notices
2. Train staff on order processing and refunds
3. Monitor first few transactions closely
4. Keep Inovio support contact handy

## Troubleshooting

### Installation Issues

**Error: "Plugin could not be activated because it triggered a fatal error"**

*Solution:*
```bash
# Check PHP error log
tail -f /var/log/php-error.log

# Common causes:
# - PHP version too old (need 5.2.4+)
# - Missing cURL extension
# - File permission issues

# Fix permissions
chmod -R 755 wp-content/plugins/inovio-payment-gateway
```

**Error: "The plugin does not have a valid header"**

*Solution:*
- Ensure `woocommerce-inovio-gateway.php` is in the root of plugin folder
- Correct structure: `plugins/inovio-payment-gateway/woocommerce-inovio-gateway.php`

### Database Issues

**Tables not created on activation**

*Solution:*
```bash
# Manually create tables via MySQL
mysql -u username -p database_name

# Paste SQL from includes/installer/inovio-plugin-database-table.php
```

Or deactivate and reactivate with debug:
```php
// Add to wp-config.php temporarily
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
```

### Payment Processing Issues

**Error: "Invalid API endpoint URL"**

*Solution:*
- Verify URL is exactly: `https://gateway.inoviopay.com/payment/pmt_service.cfm`
- No trailing spaces or slashes
- Must start with `https://`

**Error: "Please contact to service provider"**

*Solution:*
- API credentials are incorrect
- Double-check Site ID, Username, Password
- Contact Inovio support to verify account status

**SSL Certificate Errors**

*Solution:*
```bash
# Update CA certificates on server
sudo apt-get update
sudo apt-get install ca-certificates

# Or for CentOS/RHEL
sudo yum update ca-certificates
```

### WooCommerce Subscriptions Issues

**Renewals not processing automatically**

*Solution:*
1. Check WooCommerce > Status > Scheduled Actions
2. Look for failed actions related to subscriptions
3. Verify initial payment stored token correctly:
   ```sql
   SELECT meta_value FROM wp_postmeta
   WHERE meta_key = '_inovio_gateway_scheduled_first_response'
   AND post_id = [order_id];
   ```
4. Check if `SSPI_DONE` constant is preventing duplicate runs

## Getting Help

### Support Channels

1. **Email Support**: clientsupport@inoviopay.com
2. **Merchant Portal**: https://portal.inoviopay.com/
3. **Documentation**: See README.md and DEVELOPER.md
4. **Emergency Support**: Contact your account manager

### Information to Provide

When contacting support, include:
- WordPress version
- WooCommerce version
- PHP version
- Plugin version (4.4.23)
- Error messages (exact text)
- Relevant log entries from WooCommerce logs
- Steps to reproduce the issue

---

**Installation Complete!**

Once configured and tested, your WooCommerce store will be ready to accept payments through Inovio's secure payment gateway.
