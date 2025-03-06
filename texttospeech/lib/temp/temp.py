import edge_tts,asyncio, re
import os



async def TTS(voice,message):
    
    try:
            audio_folder = os.path.join(os.path.dirname(__file__), 'audio')
            communicate = edge_tts.Communicate(message, voice)
            # directory
            # match = re.findall(r'-(\w+)Neural', voice)
            output_file = os.path.join(audio_folder, f"{voice}.mp3")

            await communicate.save(output_file) 
            print('Finished')

    except:
            print("There is an error in the input please try again")

# text = """¡Hoy es un día maravilloso! El sol brilla, y estoy rodeado 
# de amigos.No puedo esperar para celebrar juntos."""

text = """Excuse me, could you tell me how to get to the nearest tube station? I seem to have lost my way
"""

voices = [

    "en-GB-LibbyNeural",
    "en-GB-MaisieNeural",
    "en-GB-RyanNeural",
    "en-GB-SoniaNeural",
    "en-GB-ThomasNeural",
    "en-US-AnaNeural"

]
async def main():
    for voice in voices:
       await TTS(voice,text)
    # await TTS("es-VE-SebastianNeural",text)


asyncio.run(main())




