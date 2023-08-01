const hre = require("hardhat");

const contractAddress =process.env.CONTRACT_ADDRESS
const contractName ="DividendsPayout";
let call;

async function main(){
    call =  await hre.ethers.getContractAt(contractName, contractAddress);

    createCompany();
    getCompanies();
    deposit();
}

async function createCompany(){
    const createCompany = await call.addOrChangeCompany("KibokoDAOAfrica", "", "Everyone is a Kiboko", 60);
    console.log(createCompany);
}

async function getCompanies(){
    const companyAddresses = await call.getCompanies();
    console.log(companyAddresses);

    companyAddresses.forEach(async (address) => {
        const company = await call.getCompany(address);
        console.log(company);
    });
}

async function deposit(){
    const amountToDeposit = hre.ethers.utils.parseUnits("30", "18");
    const deposit = await call.deposit({value: amountToDeposit});
    const receipt = await deposit.wait();
    console.log(receipt);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });