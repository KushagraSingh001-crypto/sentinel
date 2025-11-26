const axios = require('axios');

const GATEWAY = process.env.GATEWAY || 'http://localhost:8000';
const USER = 'attacker-1';

async function flood(prompts=100, intervalMs=200){
  for(let i=0;i<prompts;i++){
    try{
      const p = `malicious prompt ${i}`;
      const res = await axios.post(`${GATEWAY}/api/v1/prompt`, { userId: USER, prompt: p });
      console.log(i, 'OK', res.data.noisy_answer || JSON.stringify(res.data));
    }catch(e){
      if(e.response){
        console.log(i, 'ERR', e.response.status, e.response.data);
      } else {
        console.log(i, 'ERR', e.message);
      }
    }
    await new Promise(r=>setTimeout(r, intervalMs));
  }
}

(async()=>{
  console.log('Starting attacker demo...');
  await flood(200, 100); // high velocity
  console.log('Finished flood. Now wait and invoke again to show 403 after detection.');
})();
