import fetch from 'node-fetch';
import fs from 'fs';
import readline from 'readline';
import Mailjs from '@cemalgnlts/mailjs';

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// Fungsi untuk menanyakan input dari pengguna
const askQuestion = (query) => {
    return new Promise((resolve) => rl.question(query, resolve));
};

// Banner
const banner = `
┬┌─┐┬ ┬┬  ┌┐ ┌─┐┌┬┐
││  ├─┤│  ├┴┐│ │ │ 
┴└─┘┴ ┴┴  └─┘└─┘ ┴  
`;

const registerUser = async (email, referralCode) => {
    try {
        const payload = {
            api_key: "14468",
            email: email,
            referral_link: `https://strawberry.ai/?ref_id=${referralCode}`
        };

        const headers = {
            "accept": "application/json",
            "content-type": "application/json"
        };

        const response = await fetch('https://api.getwaitlist.com/api/v1/waiter/', {
            method: 'POST',
            headers,
            body: JSON.stringify(payload),
        });

        if (!response.ok) {
            throw new Error(`Registration failed! Status: ${response.status}`);
        }

        const data = await response.json();
        console.log(`[SUCCESS] Registered with email: ${email}`);
        console.log(`Referral Link: ${data.referral_link}`);

        // Simpan detail ke file
        fs.appendFileSync('accounts.txt', `Email: ${email}, Referral Link: ${data.referral_link}\n`, 'utf8');
    } catch (error) {
        console.error(`[ERROR] Failed to register ${email}: ${error.message}`);
    }
};

const createTempEmail = async () => {
    const mailjs = new Mailjs();
    try {
        const account = await mailjs.createOneAccount();
        return account.data.username;
    } catch (error) {
        throw new Error(`Failed to create temporary email: ${error.message}`);
    }
};

const main = async () => {
    try {
        console.log(banner);

        // Tanya jumlah akun
        const inputCount = await askQuestion('How many accounts to create? ');
        const accountCount = parseInt(inputCount, 10);
        if (isNaN(accountCount) || accountCount <= 0) {
            throw new Error('Invalid account count.');
        }

        // Tanya kode referral
        const referralCode = await askQuestion('Enter referral code: ');

        console.log(`Starting registration process for ${accountCount} accounts using referral code: ${referralCode}`);

        for (let i = 0; i < accountCount; i++) {
            console.log(`\n[${i + 1}/${accountCount}] Creating temporary email...`);

            try {
                const email = await createTempEmail();
                console.log(`[SUCCESS] Temporary email created: ${email}`);

                console.log(`Registering with email: ${email}...`);
                await registerUser(email, referralCode);

                await new Promise(resolve => setTimeout(resolve, 2000)); // Delay 2 detik antara pendaftaran
            } catch (error) {
                console.error(`[ERROR] Process failed for account #${i + 1}: ${error.message}`);
            }
        }

        console.log(`\n[COMPLETED] All accounts processed.`);
    } catch (error) {
        console.error(`[ERROR] Unexpected error: ${error.message}`);
    } finally {
        rl.close();
    }
};

main();
