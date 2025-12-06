from fastapi import FastAPI , Form , Body
from fastapi.responses import StreamingResponse
from langchain_community.document_loaders import PyMuPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain import PromptTemplate
from langchain.chains.question_answering import load_qa_chain
from langchain.chains import ConversationChain
from langchain.memory import ConversationSummaryMemory
from langchain_google_genai import ChatGoogleGenerativeAI
from pydantic import BaseModel
import uvicorn
import json
import os
import warnings
warnings.filterwarnings("ignore")
app = FastAPI()
os.environ["GOOGLE_API_KEY"] = "Enter Your API Key"
llm = ChatGoogleGenerativeAI(model="gemini-2.0-flash",temperature=0.3,convert_system_message_to_human=True,streaming=True)

query = "IoT"

# doc = PyPDFLoader(r"F:\Internet_of_Things_IoT.pdf").load()
doc = PyMuPDFLoader(r"sources/Internet_of_Things_IoT.pdf").load()

text_document = ""
for i in doc:
    text_document += i.page_content

documents = [text_document]
metadatas = [{"document":query}]
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000,chunk_overlap=200)
normal_chunk = text_splitter.create_documents(documents,metadatas=metadatas)

embedding = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vector_db = FAISS.from_documents(normal_chunk,embedding)

combine_template = "\n".join([
    "Given intermediate contexts for a question, generate a final answer.",
    "### Summaries:",
    "{summaries}",
    "",
    "### Question:",
    "{question}",
    "",
    "### Final Answer:"
])
combine_prompt = PromptTemplate(
    template=combine_template,
    input_variables=["summaries","question"],
)

qna_template = "\n".join([
    "Answer the next question using the provided context.",
    "if the answer is not contained in the context , say 'NO ANSWER IS AVALIABLE'",
    "without tell me on answer based on context or it's equivalent."
    "### Context:",
    "{context}\n",
    "### Question:",
    "{question}\n",
    "### Answer:",
])

qna_prompt = PromptTemplate(
    template=qna_template,
    input_variables = ["context","question"],
    verbose=True
)
map_reduce_chain = load_qa_chain(llm,
                                 chain_type="map_reduce",
                                 return_intermediate_steps=True,  # optional
                                 question_prompt=qna_prompt,
                                 combine_prompt=combine_prompt
                                 )


# conversation = ConversationChain(
#     llm=llm,
#     memory=ConversationSummaryMemory(llm=llm ,input_key= "input"),
#     input_key="input"   # ← مهم جداً
# )
@app.post("/Ask")
async def Ask(query_question:str = Form(...)):
    try:
        similar_docs = vector_db.similarity_search(query_question,k=4,filter=metadatas[0])
        context = "\n\n".join([doc.page_content for doc in similar_docs])
        prompt = f"""
        Answer the question using the provided context.
        If the answer is not in the context, say 'NO ANSWER IS AVAILABLE'.

        ### Context:
        {context}

        ### Question:
        {query_question}

        ### Answer:
        """

        async def stream_generator():
        # llm.stream يولّد text token-by-token
            async for event in llm.astream(prompt):
                if hasattr(event, "content") and event.content:
                    yield event.content
        return StreamingResponse(stream_generator(),media_type="text/plain")
        # final_answer = map_reduce_chain(
        # {
        #     "input_documents":similar_docs,
        #     "question":data.query_question
        # },
        # return_only_outputs=True
        # )
        # output = {'response':final_answer['output_text']}
        # return output
    except:
        return "model AI is have problems right now"

if(__name__ == "__main__"):
    uvicorn.run("testRag:app",host="0.0.0.0",port=8000)