import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID")!;
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN")!;
const TWILIO_PHONE_NUMBER = Deno.env.get("TWILIO_PHONE_NUMBER")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function enviarSMS(para: string, mensagem: string) {
  const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;

  const body = new URLSearchParams({
    From: TWILIO_PHONE_NUMBER,
    To: para,
    Body: mensagem,
  });

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body.toString(),
  });

  const data = await response.json();
  console.log("SMS enviado:", data.sid ?? data);
}

function formatarTelefone(telefone: string): string {
  // Remove tudo que não for número
  const numeros = telefone.replace(/\D/g, "");
  
  // Se já tiver 13 dígitos com 55 na frente, só adiciona o +
  if (numeros.length === 13 && numeros.startsWith("55")) {
    return `+${numeros}`;
  }
  
  // Se tiver 11 dígitos (DDD + número), adiciona +55
  if (numeros.length === 11) {
    return `+55${numeros}`;
  }

  // Se tiver 10 dígitos (sem o 9), adiciona +55
  if (numeros.length === 10) {
    return `+55${numeros}`;
  }

  return `+55${numeros}`; // fallback
}

serve(async (req) => {
  try {
    
    console.log("🚀 Função iniciada");
    
    const { data: pilotos, error } = await supabase
      .from("pilotos")
      .select("janela_id, nome, telefone, categoria")
      .in("status", ["pista", "aguardando"])
      .not("janela_id", "is", null)
      .order("janela_id", { ascending: true });

    console.log("📋 Pilotos encontrados:", JSON.stringify(pilotos));
    console.log("❌ Erro:", error);

    if (error) throw error;

    // 2. Agrupa por janela_id mantendo a ordem
    const grupos = new Map<number, typeof pilotos>();
    for (const p of pilotos!) {
      if (!grupos.has(p.janela_id)) grupos.set(p.janela_id, []);
      grupos.get(p.janela_id)!.push(p);
    }

    const janelas = Array.from(grupos.values());
    // janelas[0] = voando agora, janelas[1] = próxima, janelas[2] = segunda, etc.

    // 3. Notifica cada janela com sua posição atual
    for (let i = 1; i < janelas.length; i++) {
      const janela = janelas[i];
      const posicao = i; // 1 = próxima, 2 = segunda, etc.

      let mensagem = "";
      if (posicao === 1) {
        mensagem =
          `✈️ ATENÇÃO! Você é o PRÓXIMO a voar!\n` +
          `Categoria: ${janela[0].categoria.toUpperCase()}\n` +
          `Prepare-se, sua janela começa em breve.`;
      } else {
        mensagem =
          `📋 Atualização da fila de voo:\n` +
          `Categoria: ${janela[0].categoria.toUpperCase()}\n` +
          `Você está na posição ${posicao} da fila.`;
      }

      for (const piloto of janela) {
        if (piloto.telefone) {
          const telefoneFormatado = formatarTelefone(piloto.telefone);
          console.log("📱 Enviando para:", telefoneFormatado);
          await enviarSMS(telefoneFormatado, mensagem);
        }   
      }
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Erro:", e);
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});